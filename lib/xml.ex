defmodule XML do
  @moduledoc ~s|
  A helper that makes easy working with XML.

  ## Examples

      iex> xml = XML.from_document("<person><name>Alice</name><age>30</age></person>")
      iex> XML.xpath(xml, "//name/text()")
      "Alice"
      iex> XML.xpath(xml, "//age/text()")
      "30"

  |

  import Record

  @opaque element :: :xmerl.simple_element()
  @type t :: %__MODULE__{element: element}

  defstruct [:element]

  for {name, fields} <- extract_all(from_lib: "xmerl/include/xmerl.hrl") do
    defrecordp name, fields
  end

  @doc ~s|
  Handles the sigil `~XML` for creating XML structs.

  ## Examples

      iex> ~XML[<hello>world</hello>]
      ~XML[<hello>world</hello>]

  |
  defmacro sigil_XML({:<<>>, _meta, [element]}, []) do
    quote do: XML.from_document(unquote(element))
  end

  @doc ~s|
  Parses an XML document from a binary string.

  ## Examples

      iex> xml = XML.from_document("<book><title>1984</title><author>George Orwell</author></book>")
      iex> XML.xpath(xml, "//title/text()")
      "1984"

  |
  @spec from_document(element :: binary) :: t
  def from_document(element) when is_binary(element) do
    {element, ~c""} = :xmerl_scan.string(to_charlist(element), quiet: true, space: :normalize)

    struct!(__MODULE__, element: to_tree(element))
  end

  @doc ~s|
  Generates a new XML struct for the given element.

  ## Examples

      iex> XML.new({:book, [], [{:title, [], 1984}, {:author, [], "George Orwell"}]})
      iex> ~XML[<book><title>1984</title><author>George Orwell</author></book>]

  |
  @spec new(element) :: t
        when element:
               {atom, list(element) | term}
               | {atom, Enumerable.t({atom, term}), list(element) | term}
  def new(element) do
    struct!(__MODULE__, element: normalize_element(element))
  end

  defp normalize_element({tag, attributes, element}) do
    attributes = Keyword.new(attributes, fn {k, v} -> {k, encode_element(v)} end)
    {tag, attributes, element_element(element)}
  end

  defp normalize_element({tag, element}) do
    {tag, element_element(element)}
  end

  defguardp is_charlist(value) when is_list(value) and is_integer(hd(value))

  defp element_element(value) do
    cond do
      is_nil(value) -> ~c""
      is_charlist(value) -> value
      is_list(value) -> Enum.map(value, &normalize_element/1)
      :otherwise -> encode_element(value)
    end
  end

  defp encode_element(term) do
    term
    |> to_string()
    |> to_charlist()
  end

  @doc ~s|
  Converts an XML struct to iodata.

  ## Examples

      iex> xml = XML.from_document("<greeting>Hello</greeting>")
      iex> IO.iodata_to_binary(XML.to_iodata(xml))
      "<greeting>Hello</greeting>"

  |
  @spec to_iodata(xml :: t) :: iodata
  def to_iodata(%__MODULE__{element: element}) do
    :xmerl.export_simple_element(element, :xmerl_xml_indent)
  end

  @doc ~s|
  Queries an XML document using XPath.

  ## Examples

      iex> xml = ~XML"""
      ...> <catalog>
      ...>   <book id="1"><title>1984</title><price>15.99</price></book>
      ...>   <book id="2"><title>Brave New World</title><price>14.99</price></book>
      ...> </catalog>
      ...> """
      iex> XML.xpath(xml, "//title/text()")
      ["1984", "Brave New World"]
      iex> XML.xpath(xml, "//book[@id='1']")
      ~XML[<book id="1"><title>1984</title><price>15.99</price></book>]
      iex> XML.xpath(xml, "//book[@id='1']/@id")
      "1"

  |
  @spec xpath(xml :: t, path :: binary) :: nil | result | [result] when result: binary | t
  def xpath(%__MODULE__{element: element}, path) when is_binary(path) do
    result =
      path
      |> String.to_charlist()
      |> :xmerl_xpath.string(:xmerl_lib.normalize_element(element))
      |> Enum.map(fn
        binary when is_binary(binary) -> binary
        xmlAttribute(value: value) -> to_string(value)
        xmlText(value: value) -> to_string(value)
        xmlElement() = element -> struct!(__MODULE__, element: to_tree(element))
      end)

    case result do
      [] -> nil
      [value] -> value
      values -> values
    end
  end

  @doc false
  def fetch(%__MODULE__{} = xml, path) when is_binary(path) do
    {:ok, xpath(xml, path)}
  end

  defp to_tree(element) do
    [element] = :xmerl_lib.remove_whitespace([element])
    :xmerl_lib.simplify_element(element)
  end

  defimpl String.Chars do
    def to_string(xml), do: IO.iodata_to_binary(XML.to_iodata(xml))
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(xml, opts) do
      concat([
        color_doc("~XML[", :map, opts),
        inspect_element(xml.element, opts),
        color_doc("]", :map, opts)
      ])
    end

    defp inspect_element({tag, attributes, element}, opts) do
      tag_attributes =
        for {name, value} <- attributes do
          concat([
            color_doc(" #{name}=", :map, opts),
            color_doc(~s["#{value}"], :string, opts)
          ])
        end

      open_tag =
        concat([
          color_doc("<#{tag}", :map, opts),
          concat(tag_attributes),
          color_doc(">", :map, opts)
        ])

      close_tag = color_doc("</#{tag}>", :map, opts)

      container_doc(open_tag, element, close_tag, opts, &inspect_element/2,
        separator: "",
        break: :strict
      )
    end

    defp inspect_element(charlist, opts) do
      color_doc(to_string(charlist), :string, opts)
    end
  end
end
