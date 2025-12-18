defmodule XML do
  import Record

  @opaque document :: :xmerl.element()
  @type t :: %__MODULE__{document: document}

  defstruct [:document]

  # defrecord :xmlDocument, extract(:xmlDocument, from_lib: "xmerl/include/xmerl.hrl")
  # defrecord :xmlElement, extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  defrecord :xmlAttribute, extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")
  # defrecord :xmlText, extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  # defrecord :xmlObj, extract(:xmlObj, from_lib: "xmerl/include/xmerl.hrl")

  defmacro sigil_XML({:<<>>, _, [content]}, []) do
    quote do: XML.from_document(unquote(content))
  end

  def from_document(content) when is_binary(content) do
    {document, []} = :xmerl_scan.string(to_charlist(content), quiet: true)
    struct!(__MODULE__, document: document)
  end

  def to_document(%__MODULE__{} = xml) do
    :xmerl.export_element(xml.document, :xmerl_xml)
  end

  def to_string(%__MODULE__{document: nodes}) when is_list(nodes) do
    nodes
    |> Enum.map(fn
      xmlAttribute(value: value) -> value
      node -> :xmerl.export_simple_element(node, :xmerl_xml)
    end)
    |> IO.iodata_to_binary()
  end

  def to_string(%__MODULE__{} = xml) do
    IO.iodata_to_binary(to_document(xml))
  end

  def search(%__MODULE__{document: document}, xpath) when is_binary(xpath) do
    results =
      document
      |> List.wrap()
      |> Enum.flat_map(fn node -> :xmerl_xpath.string(to_charlist(xpath), node) end)

    case results do
      [] -> nil
      nodes -> struct!(__MODULE__, document: nodes)
    end
  end

  @doc false
  def fetch(%__MODULE__{} = xml, xpath) when is_binary(xpath) do
    {:ok, search(xml, xpath)}
  end

  defimpl String.Chars do
    defdelegate to_string(xml), to: @for
  end

  # defimpl Inspect do
  #   import Inspect.Algebra

  #   def inspect(xml, inspect_opts) do
  #     collection = XML.to_string(xml)

  #     fun = fn i, opts ->
  #       IO.inspect(i)
  #       to_string(i)
  #     end

  #     opts = [separator: "", break: :flex]

  #     container_doc("~XML[", collection, "]", inspect_opts, fun, opts)
  #   end
  # end
end
