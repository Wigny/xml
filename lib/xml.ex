defmodule XML do
  @moduledoc ~s|
  A helper that makes easy working with XML.

  ## Examples

      iex> person = XML.parse("<person><name>Alice</name><age>30</age></person>")
      iex> XML.text(person["name"])
      "Alice"

  |

  @type element :: {tag :: term, [{attribute :: term, value :: term}], [element | term]}
  @type t :: %__MODULE__{element: element}

  defstruct [:element]

  @doc ~s|
  Handles the sigil `~XML` for creating XML structs.

  ## Examples

      iex> ~XML[<hello>world</hello>]
      ~XML[<hello>world</hello>]

  |
  defmacro sigil_XML({:<<>>, _meta, [element]}, []) do
    quote do: XML.parse(unquote(element))
  end

  @doc ~s|
  Parses an XML document from a binary string.

  ## Examples

      iex> XML.parse("<hello>world</hello>")
      ~XML[<hello>world</hello>]

  |
  @spec parse(content :: binary) :: t
  def parse(content) when is_binary(content) do
    struct!(__MODULE__, element: XML.Parser.parse(content))
  end

  defguardp is_element(element)
            when is_tuple(element) and tuple_size(element) == 3 and
                   is_list(elem(element, 1)) and is_list(elem(element, 2))

  @doc ~s|
  Generates a new XML struct with the given element tree.

  ## Examples

      iex> XML.new({"person", [], [{"name", [], ["Alice"]}, {"age", [], ["30"]}]})
      ~XML[<person><name>Alice</name><age>30</age></person>]

  |
  @spec new(element) :: t
  def new(element) when is_element(element) do
    struct!(__MODULE__, element: element)
  end

  @doc ~s|
  Helper for building XML element tuples with tag name, attributes, and content.

  Returns an element tree that can be composed with other `element/3` calls or encoded with
  `XML.Encoder.encode/1`.

  ## Examples

      iex> element = XML.element("person", [{"id", "1"}], [
      ...>   XML.element("name", [], ["Alice"]),
      ...>   XML.element("age", [], ["30"])
      ...> ])
      iex> XML.new(element)
      ~XML[<person id="1"><name>Alice</name><age>30</age></person>]

  |
  @spec element(tag :: term, attributes :: list, content :: list) :: element
  def element(tag, attributes, content) when is_list(attributes) and is_list(content) do
    {tag, attributes, content}
  end

  @doc ~s|
  Converts an XML struct to iodata.

  ## Options

    * `:indent` - Number of spaces used when indenting (default: 0, no formatting)

  ## Examples

      iex> iodata = XML.to_iodata(~XML"<greeting>Hello</greeting>")
      iex> IO.iodata_to_binary(iodata)
      "<greeting>Hello</greeting>"

      iex> iodata = XML.to_iodata(~XML"<person><name>Alice</name><age>30</age></person>", indent: 2)
      iex> IO.iodata_to_binary(iodata)
      "<person>\\n  <name>\\n    Alice\\n  </name>\\n  <age>\\n    30\\n  </age>\\n</person>\\n"

  |
  @spec to_iodata(xml :: t, opts :: keyword) :: iodata
  def to_iodata(%__MODULE__{element: element}, opts \\ []) when is_element(element) do
    XML.Encoder.encode(element, opts)
  end

  @doc ~s|
  Gets the value of an attribute from an XML element.

  ## Examples

      iex> XML.attribute(~XML[<person name="Alice" age="30"/>], "name")
      "Alice"

  |
  @spec attribute(xml :: t, name :: binary) :: binary
  def attribute(%__MODULE__{element: {_tag, attribute, _content}}, name) do
    with {^name, value} <- List.keyfind(attribute, name, 0), do: value
  end

  @doc ~s|
  Extracts text content from an XML element.

  ## Examples

      iex> XML.text(~XML[<greeting>Hello</greeting>])
      "Hello"

      iex> XML.text(~XML[<person><name>Alice</name><name>Bob</name></person>])
      ["Alice", "Bob"]

      iex> XML.text(~XML[<empty/>])
      nil

  |
  @spec text(xml :: t) :: nil | binary | [binary]
  def text(%__MODULE__{element: element}) when is_element(element) do
    case List.flatten(element_text(element)) do
      [] -> nil
      [text] -> text
      texts -> texts
    end
  end

  defp element_text({_tag, _attribute, content}), do: Enum.map(content, &element_text/1)
  defp element_text(content), do: String.trim(to_string(content))

  @doc false
  def fetch(%__MODULE__{} = xml, tag) when is_binary(tag) do
    {_tag, _attr, content} = xml.element

    case Enum.filter(content, &match?({^tag, _attr, _content}, &1)) do
      [] -> :error
      [element] -> {:ok, new(element)}
      elements -> {:ok, Enum.map(elements, &new/1)}
    end
  end

  defimpl String.Chars do
    def to_string(xml), do: IO.iodata_to_binary(XML.to_iodata(xml))
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(xml, opts) do
      concat([
        color_doc("~XML[", :map, opts),
        inspect_element(xml.element, opts),
        color_doc("]", :map, opts)
      ])
    end

    defp inspect_element({tag, attributes, element}, opts) do
      tag_attributes =
        for {name, value} <- attributes do
          concat([
            color_doc(" #{name}=", :map, opts),
            color_doc(~s["#{value}"], :string, opts)
          ])
        end

      open_tag =
        concat([
          color_doc("<#{tag}", :map, opts),
          concat(tag_attributes),
          color_doc(">", :map, opts)
        ])

      close_tag = color_doc("</#{tag}>", :map, opts)

      container_doc(open_tag, element, close_tag, opts, &inspect_element/2,
        separator: "",
        break: :strict
      )
    end

    defp inspect_element(content, opts) do
      color_doc(to_string(content), :string, opts)
    end
  end
end
