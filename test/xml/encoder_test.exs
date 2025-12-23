defmodule XML.EncoderTest do
  use ExUnit.Case

  alias XML.Encoder

  defmodule Person do
    @derive {XML.Encoder, {:person, [:id], [:name, :email]}}

    defstruct [:id, :name, :email]
  end

  defimpl XML.Encoder, for: Duration do
    defdelegate encode(duration), to: Duration, as: :to_iso8601
  end

  doctest Encoder

  test "impl" do
    assert IO.iodata_to_binary(XML.Encoder.encode(~s[<>&"'])) == "&lt;&gt;&amp;&quot;&apos;"
    assert IO.iodata_to_binary(XML.Encoder.encode(nil)) == ""
    assert IO.iodata_to_binary(XML.Encoder.encode(:<)) == "&lt;"
    assert IO.iodata_to_binary(XML.Encoder.encode(123)) == "123"
    assert IO.iodata_to_binary(XML.Encoder.encode(3.14)) == "3.14"
    assert IO.iodata_to_binary(XML.Encoder.encode(["a", "b", "c"])) == "abc"

    person = %Person{id: 1, name: "John", email: "john@example.com"}

    assert IO.iodata_to_binary(XML.Encoder.encode(person)) ==
             ~s'<person id="1"><name>John</name><email>john@example.com</email></person>'

    assert IO.iodata_to_binary(XML.Encoder.encode(%{key: :value})) == "<key>value</key>"

    assert IO.iodata_to_binary(XML.Encoder.encode(%{key: [1, %{nested: true}]})) ==
             "<key>1<nested>true</nested></key>"

    assert IO.iodata_to_binary(XML.Encoder.encode({:tag, [attr: 1], [:content]})) ==
             ~s'<tag attr="1">content</tag>'
  end
end
