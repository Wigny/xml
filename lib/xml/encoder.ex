defprotocol XML.Encoder do
  @moduledoc """
  Protocol for encoding Elixir data structures into XML.

  The `XML.Encoder` protocol converts Elixir values into XML-formatted `iodata`.

  ## Deriving

  Structs can derive the protocol to automatically generate XML elements:

      defmodule Person do
        @derive {XML.Encoder, {:person, [:id], [:name, :email]}}
        defstruct [:id, :name, :email]
      end

      iex> iodata = XML.Encoder.encode(%Person{id: 1, name: "Alice", email: "alice@example.com"})
      iex> IO.iodata_to_binary(iodata)
      ~s(<person id="1"><name>Alice</name><email>alice@example.com</email></person>)

  ## Implementing

  Custom types can implement the protocol for specialized encoding:

      defimpl XML.Encoder, for: Duration do
        defdelegate encode(duration), to: Duration, as: :to_iso8601
      end

      iex> XML.Encoder.encode(Duration.new!(minute: 5, second: 30))
      "PT5M30S"

  """

  @spec encode(value :: term) :: iodata
  def encode(value)

  defmacro __deriving__(module, {tag, attributes, content}) do
    quote do
      defimpl XML.Encoder, for: unquote(module) do
        def encode(struct) do
          XML.Encoder.encode({
            unquote(tag),
            Map.take(struct, unquote(attributes)),
            Enum.map(Map.take(struct, unquote(content)), fn {k, v} -> {k, [], [v]} end)
          })
        end
      end
    end
  end
end

defimpl XML.Encoder, for: Tuple do
  def encode({tag, attributes, []}) do
    [?<, to_string(tag), encode_attributes(attributes), ?/, ?>]
  end

  def encode({tag, attributes, content}) when is_list(content) do
    encoded_tag = to_string(tag)
    encoded_attributes = encode_attributes(attributes)
    encoded_content = XML.Encoder.List.encode(content)
    [?<, encoded_tag, encoded_attributes, ?>, encoded_content, ?<, ?/, encoded_tag, ?>]
  end

  defp encode_attributes([]) do
    []
  end

  defp encode_attributes([{name, value} | attributes]) do
    [?\s, to_string(name), ?=, ?", XML.Encoder.encode(value), ?" | encode_attributes(attributes)]
  end
end

defimpl XML.Encoder, for: Map do
  def encode(value) do
    encode_entries(Map.to_list(value))
  end

  defp encode_entries([]) do
    []
  end

  defp encode_entries([{key, value} | rest]) do
    [XML.Encoder.encode({key, [], List.wrap(value)}) | encode_entries(rest)]
  end
end

defimpl XML.Encoder, for: List do
  def encode([]), do: []
  def encode([head | tail]), do: [XML.Encoder.encode(head) | encode(tail)]
end

defimpl XML.Encoder, for: [Integer, Float] do
  def encode(value), do: to_string(value)
end

defimpl XML.Encoder, for: Atom do
  def encode(value), do: XML.Encoder.encode(to_string(value))
end

defimpl XML.Encoder, for: BitString do
  def encode(value) when is_binary(value), do: escape(value, [])

  defp escape(<<?<, rest::binary>>, acc), do: escape(rest, [acc, "&lt;"])
  defp escape(<<?>, rest::binary>>, acc), do: escape(rest, [acc, "&gt;"])
  defp escape(<<?&, rest::binary>>, acc), do: escape(rest, [acc, "&amp;"])
  defp escape(<<?", rest::binary>>, acc), do: escape(rest, [acc, "&quot;"])
  defp escape(<<?', rest::binary>>, acc), do: escape(rest, [acc, "&apos;"])
  defp escape(<<char, rest::binary>>, acc), do: escape(rest, [acc, char])
  defp escape(<<>>, acc), do: acc
end
