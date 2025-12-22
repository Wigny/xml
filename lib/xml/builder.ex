defprotocol XML.Builder do
  @moduledoc """
  Protocol for converting Elixir data structures into XML elements.

  Converts values to the element format (`t:XML.element/0`) used by the XML module.

  ## Deriving

      defmodule Person do
        @derive {XML.Builder, {:person, [:id], [:name, :email]}}
        defstruct [:id, :name, :email]
      end

      iex> XML.Builder.element(%Person{id: 1, name: "Alice", email: "alice@example.com"})
      {"person", [{"id", "1"}], [{"name", [], ["Alice"]}, {"email", [], ["alice@example.com"]}]}

  ## Implementing

      defimpl XML.Builder, for: Postgrex.INET do
        def element(%Postgrex.INET{address: address}), do: to_string(:inet.ntoa(address))
      end

      iex> XML.Builder.element(%Postgrex.INET{address: {127, 0, 0, 1}})
      "127.0.0.1"

  """

  @spec element(value :: term) :: XML.element()
  def element(value)

  defmacro __deriving__(module, {tag, attributes, content}) do
    quote do
      defimpl XML.Builder, for: unquote(module) do
        def element(struct) do
          XML.Builder.element({
            unquote(tag),
            Map.take(struct, unquote(attributes)),
            Enum.map(Map.take(struct, unquote(content)), fn {k, v} -> {k, [], [v]} end)
          })
        end
      end
    end
  end
end

defimpl XML.Builder, for: Tuple do
  def element({tag, attributes, content}) do
    {
      to_string(tag),
      Enum.map(attributes, fn {k, v} -> {to_string(k), XML.Builder.element(v)} end),
      XML.Builder.element(content)
    }
  end
end

defimpl XML.Builder, for: List do
  def element(value), do: Enum.map(value, &XML.Builder.element/1)
end

defimpl XML.Builder, for: [Atom, BitString, Integer, Float] do
  def element(value), do: to_string(value)
end
