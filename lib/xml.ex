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

  @opaque content :: [:xmerl.simple_element()]
  @type t :: %__MODULE__{content: content}

  defstruct [:content]

  for {name, fields} <- extract_all(from_lib: "xmerl/include/xmerl.hrl") do
    defrecordp name, fields
  end

  @doc ~s|
  Handles the sigil `~XML` for creating XML structs.

  ## Examples

      iex> ~XML[<hello>world</hello>]
      ~XML[<hello>world</hello>]

  |
  defmacro sigil_XML({:<<>>, _meta, [content]}, []) do
    quote do: XML.from_document(unquote(content))
  end

  @doc ~s|
  Parses an XML document from a binary string.

  ## Examples

      iex> xml = XML.from_document("<book><title>1984</title><author>George Orwell</author></book>")
      iex> XML.xpath(xml, "//title/text()")
      "1984"

  |
  @spec from_document(content :: binary) :: t
  def from_document(content) when is_binary(content) do
    {element, ~c""} = :xmerl_scan.string(to_charlist(content), quiet: true, space: :normalize)

    struct!(__MODULE__, content: to_tree(element))
  end

  @doc ~s|
  Generates a new XML struct for the given content.

  ## Examples

      iex> XML.new({:book, [], [{:title, [], 1984}, {:author, [], "George Orwell"}]})
      iex> ~XML[<book><title>1984</title><author>George Orwell</author></book>]
  |
  @spec new(content :: list(element) | element) :: t
        when element:
               {atom, list(element) | term}
               | {atom, Enumerable.t({atom, term}), list(element) | term}
  def new(content) do
    struct!(__MODULE__, content: Enum.map(List.wrap(content), &tree_element/1))
  end

  defp tree_element({tag, attributes, content}) do
    attributes = Keyword.new(attributes, fn {k, v} -> {k, encode_content(v)} end)
    {tag, attributes, element_content(content)}
  end

  defp tree_element({tag, content}) do
    {tag, element_content(content)}
  end

  defguardp is_charlist(value) when is_list(value) and is_integer(hd(value))

  defp element_content(value) do
    cond do
      is_nil(value) -> ~c""
      is_charlist(value) -> value
      is_list(value) -> Enum.map(value, &tree_element/1)
      :otherwise -> encode_content(value)
    end
  end

  defp encode_content(term) do
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
  def to_iodata(%__MODULE__{content: content}) do
    :xmerl.export_simple_content(content, :xmerl_xml_indent)
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
  @spec xpath(xml :: t, path :: binary) :: node | value | [node | value]
        when node: t, value: binary
  def xpath(%__MODULE__{content: content}, path) when is_binary(path) do
    result =
      for element <- :xmerl_lib.normalize_content(content),
          node <- :xmerl_xpath.string(String.to_charlist(path), element) do
        case node do
          binary when is_binary(binary) -> binary
          xmlAttribute(value: value) -> to_string(value)
          xmlText(value: value) -> to_string(value)
          xmlElement() = element -> struct!(__MODULE__, content: to_tree(element))
        end
      end

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

  defp to_tree(elements) do
    elements
    |> List.wrap()
    |> :xmerl_lib.remove_whitespace()
    |> :xmerl_lib.simplify_content()
  end

  defimpl String.Chars do
    def to_string(xml), do: IO.iodata_to_binary(XML.to_iodata(xml))
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(xml, opts) do
      container_doc("~XML[", xml.content, "]", opts, &inspect_row/2, separator: "", break: :flex)
    end

    defp inspect_row({tag, attributes, content}, opts) do
      tag_color = :map
      attribute_color = :map

      tag_attributes =
        for {name, value} <- attributes do
          concat([
            color_doc(" #{name}=", attribute_color, opts),
            color_doc(~s["#{value}"], :string, opts)
          ])
        end

      open_tag =
        concat([
          color_doc("<#{tag}", tag_color, opts),
          concat(tag_attributes),
          color_doc(">", tag_color, opts)
        ])

      close_tag = color_doc("</#{tag}>", tag_color, opts)

      container_doc(open_tag, content, close_tag, opts, &inspect_row/2,
        separator: "",
        break: :strict
      )
    end

    defp inspect_row(charlist, opts) do
      color_doc(to_string(charlist), :string, opts)
    end
  end
end
