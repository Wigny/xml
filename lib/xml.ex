defmodule XML do
  # import Record

  @opaque document :: :xmerl.element()
  @type t :: %__MODULE__{document: document}

  defstruct [:document]

  # defrecord :xmlElement, extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  # defrecord :xmlAttribute, extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")
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
    :xmerl.export_content(List.wrap(xml.document), :xmerl_xml)
  end

  def query(%__MODULE__{} = xml, xpath) when is_binary(xpath) do
    document = :xmerl_xpath.string(to_charlist(xpath), xml.document)
    struct!(__MODULE__, document: document)
  end

  @doc false
  def fetch(%__MODULE__{} = xml, xpath) when is_binary(xpath) do
    {:ok, query(xml, xpath)}
  end

  defimpl String.Chars do
    def to_string(xml) do
      xml
      |> XML.to_document()
      |> IO.iodata_to_binary()
    end
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
