defmodule XML.IOData do
  @moduledoc false

  @spec escape(value :: binary) :: iodata
  def escape(value, acc \\ [])
  def escape(<<?<, rest::binary>>, acc), do: escape(rest, [acc, "&lt;"])
  def escape(<<?>, rest::binary>>, acc), do: escape(rest, [acc, "&gt;"])
  def escape(<<?&, rest::binary>>, acc), do: escape(rest, [acc, "&amp;"])
  def escape(<<?", rest::binary>>, acc), do: escape(rest, [acc, "&quot;"])
  def escape(<<?', rest::binary>>, acc), do: escape(rest, [acc, "&apos;"])
  def escape(<<char, rest::binary>>, acc), do: escape(rest, [acc, char])
  def escape(<<>>, acc), do: acc

  @type opts :: [indent: non_neg_integer, depth: non_neg_integer]

  @spec escape(opts) :: iodata
  def indent(opts), do: List.duplicate(?\s, indent_size(opts))

  @spec linebreak(opts) :: iodata
  def linebreak(opts) do
    pretty? = Keyword.get(opts, :indent, 0) > 0
    if pretty?, do: [?\n], else: []
  end

  @spec trailing_linebreak(opts) :: iodata
  def trailing_linebreak(opts) do
    root? = Keyword.get(opts, :depth, 0) == 0
    if root?, do: linebreak(opts), else: []
  end

  defp indent_size(opts) do
    indent = Keyword.get(opts, :indent, 0)
    depth = Keyword.get(opts, :depth, 0)
    indent * depth
  end
end
