defmodule XML do
  import Record

  @opaque nodes :: [:xmerl_xpath.nodeEntity()]
  @type t :: %__MODULE__{nodes: nodes}

  defstruct [:nodes]

  defrecord :xmlAttribute, extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")

  defmacro sigil_XML({:<<>>, _meta, [content]}, []) do
    quote do: XML.from_document(unquote(content))
  end

  @spec from_document(content :: binary) :: t
  def from_document(content) when is_binary(content) do
    {document, ~c""} = :xmerl_scan.string(to_charlist(content), quiet: true)
    struct!(__MODULE__, nodes: [document])
  end

  @spec to_iodata(xml :: t) :: iodata
  def to_iodata(%__MODULE__{nodes: nodes}) do
    Enum.map(nodes, fn
      xmlAttribute(value: value) -> value
      element -> :xmerl.export_element(element, :xmerl_xml)
    end)
  end

  @spec search(xml :: t, xpath :: binary) :: t | nil
  def search(%__MODULE__{nodes: nodes}, xpath) when is_binary(xpath) do
    case Enum.flat_map(nodes, &:xmerl_xpath.string(to_charlist(xpath), &1)) do
      [] -> nil
      nodes -> struct!(__MODULE__, nodes: nodes)
    end
  end

  @doc false
  def fetch(%__MODULE__{} = xml, xpath) when is_binary(xpath) do
    {:ok, search(xml, xpath)}
  end

  defimpl String.Chars do
    def to_string(xml), do: IO.iodata_to_binary(XML.to_iodata(xml))
  end

  defimpl Enumerable do
    def count(xml) do
      {:ok, length(xml.nodes)}
    end

    def member?(_xml, _element) do
      {:error, __MODULE__}
    end

    def slice(_xml) do
      {:error, __MODULE__}
    end

    def reduce(xml, acc, fun) do
      Enumerable.List.reduce(xml.nodes, acc, fn node, acc ->
        xml = struct!(XML, nodes: [node])
        fun.(xml, acc)
      end)
    end
  end
end
