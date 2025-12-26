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

      iex> iodata = XML.Encoder.encode(%Person{id: 1, name: "Alice", email: "alice@example.com"}, indent: 2)
      iex> IO.iodata_to_binary(iodata)
      ~s(<person id="1">\\n  <name>\\n    Alice\\n  </name>\\n  <email>\\n    alice@example.com\\n  </email>\\n</person>\\n)

  ## Implementing

  Custom types can implement the protocol for specialized encoding.

  For leaf values (strings, numbers, etc):

      defimpl XML.Encoder, for: Duration do
        def encode(duration, _opts), do: Duration.to_iso8601(duration)
      end

      iex> XML.Encoder.encode(Duration.new!(minute: 5, second: 30))
      "PT5M30S"

  For tree structures with nested elements, build element tuples and encode them:

      defimpl XML.Encoder, for: BlogPost do
        def encode(post, opts) do
          article = XML.element(:article, [id: post.id], [
            XML.element(:title, [], [post.title]),
            XML.element(:author, [], [post.author]),
            XML.element(:body, [], [post.body])
          ])

          XML.Encoder.encode(article, opts)
        end
      end

  Or use the tuple structure directly:

      defimpl XML.Encoder, for: BlogPost do
        def encode(post, opts) do
          article = {:article, [id: post.id], [
            {:title, [], [post.title]},
            {:author, [], [post.author]},
            {:body, [], [post.body]}
          ]}

          XML.Encoder.encode(article, opts)
        end
      end

  """

  @doc """
  Encodes a value into XML-formatted iodata.

  ## Parameters

    * `value` - The term to encode
    * `opts` - Formatting options (default: `[]`)
      * `:indent` - Number of spaces used when indenting

  """
  @spec encode(value :: term, opts :: keyword) :: iodata
  def encode(value, opts \\ [])

  defmacro __deriving__(module, {tag, attributes, content}) do
    quote do
      defimpl XML.Encoder, for: unquote(module) do
        def encode(struct, opts) do
          element =
            XML.element(
              unquote(tag),
              Map.to_list(Map.take(struct, unquote(attributes))),
              Enum.map(Map.take(struct, unquote(content)), fn {k, v} ->
                XML.element(k, [], [v])
              end)
            )

          XML.Encoder.encode(element, opts)
        end
      end
    end
  end
end

defimpl XML.Encoder, for: Tuple do
  import XML.IOData

  def encode({tag, attributes, []}, _opts) do
    [?<, to_string(tag), encode_attributes(attributes), ?\s, ?/, ?>]
  end

  def encode({tag, attributes, content}, opts) when is_list(content) do
    encoded_tag = to_string(tag)
    encoded_attributes = encode_attributes(attributes)
    encoded_content = XML.Encoder.List.encode(content, update_in(opts[:depth], &((&1 || 0) + 1)))

    [
      ?<,
      encoded_tag,
      encoded_attributes,
      ?>,
      linebreak(opts),
      encoded_content,
      indent(opts),
      ?<,
      ?/,
      encoded_tag,
      ?>,
      trailing_linebreak(opts)
    ]
  end

  defp encode_attributes([]) do
    []
  end

  defp encode_attributes([{name, value} | attributes]) do
    [?\s, to_string(name), ?=, ?", escape(to_string(value)), ?" | encode_attributes(attributes)]
  end
end

defimpl XML.Encoder, for: Map do
  def encode(value, opts) do
    encode_entries(Map.to_list(value), opts)
  end

  defp encode_entries([], _opts) do
    []
  end

  defp encode_entries([{key, value} | rest], opts) do
    [XML.Encoder.encode({key, [], List.wrap(value)}, opts) | encode_entries(rest, opts)]
  end
end

defimpl XML.Encoder, for: List do
  import XML.IOData

  def encode([], _opts), do: []

  def encode([head | tail], opts) do
    [indent(opts), XML.Encoder.encode(head, opts), linebreak(opts) | encode(tail, opts)]
  end
end

defimpl XML.Encoder, for: [Integer, Float] do
  def encode(value, _opts), do: to_string(value)
end

defimpl XML.Encoder, for: Atom do
  def encode(value, opts), do: XML.Encoder.encode(to_string(value), opts)
end

defimpl XML.Encoder, for: BitString do
  import XML.IOData

  def encode(value, _opts) when is_binary(value), do: escape(value)
end
