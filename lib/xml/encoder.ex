defprotocol XML.Encoder do
  @moduledoc """
  Protocol for encoding Elixir data structures into XML elements.

  Converts values to `:xmerl` simple elements or charlists for XML generation.

  ## Deriving

      defmodule Person do
        @derive {XML.Encoder, {:person, [:id], [:name, :email]}}
        defstruct [:id, :name, :email]
      end

      iex> XML.Encoder.element(%Person{id: 1, name: "Alice", email: "alice@example.com"})
      {:person, [id: ~c"1"], [name: ~c"Alice", email: ~c"alice@example.com"]}

  ## Implementing

      defimpl XML.Encoder, for: Postgrex.INET do
        def element(%Postgrex.INET{address: address}), do: :inet.ntoa(address)
      end

      iex> XML.Encoder.element(%Postgrex.INET{address: {127, 0, 0, 1}})
      ~c"127.0.0.1"

  """

  @spec element(value :: term) :: :xmerl.simple_element()
  def element(value)

  defmacro __deriving__(module, {tag, attributes, content}) do
    quote do
      defimpl XML.Encoder, for: unquote(module) do
        def element(struct) do
          XML.Encoder.element({
            unquote(tag),
            Map.take(struct, unquote(attributes)),
            Map.to_list(Map.take(struct, unquote(content)))
          })
        end
      end
    end
  end
end

defimpl XML.Encoder, for: Tuple do
  def element({tag, content}) do
    XML.Encoder.element({tag, [], content})
  end

  def element({tag, attributes, content}) do
    {
      tag,
      Keyword.new(attributes, fn {k, v} -> {k, XML.Encoder.element(v)} end),
      XML.Encoder.element(List.wrap(content))
    }
  end
end

defimpl XML.Encoder, for: List do
  def element(value), do: Enum.map(value, &XML.Encoder.element/1)
end

defimpl XML.Encoder, for: [Atom, BitString, Integer, Float] do
  def element(value), do: to_charlist(value)
end
