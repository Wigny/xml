defmodule XML do
  import Record

  @opaque content :: [:xmerl.simple_element()]
  @type t :: %__MODULE__{content: content}

  defstruct [:content]

  for {name, fields} <- extract_all(from_lib: "xmerl/include/xmerl.hrl") do
    defrecordp name, fields
  end

  defmacro sigil_XML({:<<>>, _meta, [content]}, []) do
    quote do: XML.from_document(unquote(content))
  end

  @spec from_document(content :: binary) :: t
  def from_document(content) when is_binary(content) do
    {element, ~c""} = :xmerl_scan.string(to_charlist(content), quiet: true, space: :normalize)

    struct!(__MODULE__, content: to_tree(element))
  end

  @spec to_iodata(xml :: t) :: iodata
  def to_iodata(%__MODULE__{content: content}) do
    :xmerl.export_simple_content(content, :xmerl_xml_indent)
  end

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
