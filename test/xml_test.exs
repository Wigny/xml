defmodule XMLTest do
  use ExUnit.Case

  import XML, only: [sigil_XML: 2]

  doctest XML

  @xml ~XML"""
  <doc>
    <points>
      <point x="1" y="2"/>
      <point x="3" y="4"/>
      <point x="5" y="6"/>
    </points>
    <strings>
      <string>foo</string>
      <string>bar</string>
    </strings>
  </doc>
  """

  test "new/1" do
    assert XML.new({:points, [], [{:point, %{x: 1, y: 2}, nil}]}) ==
             ~XML'<points><point x="1" y="2"></point></points>'

    assert XML.new({:points, [{:point, [x: 1, y: 2], "x"}]}) ==
             ~XML'<points><point x="1" y="2">x</point></points>'
  end

  test "from_document/1" do
    assert %XML{element: element} = XML.from_document("<string>foo</string>")
    assert element == {:string, [], [~c"foo"]}
  end

  test "to_iodata/1" do
    assert iodata = XML.to_iodata(~XML[<point x="1" y="2"/>])
    assert IO.iodata_to_binary(iodata) == ~s[<point x="1" y="2"/>]
  end

  test "to_string/1" do
    assert to_string(~XML"<string>bar</string>") == "<string>bar</string>"
  end

  test "xpath/2" do
    assert XML.xpath(@xml, "//point[1]") == ~XML[<point x="1" y="2"/>]
    assert XML.xpath(@xml, "//string[last()]/text()") == "bar"
    assert XML.xpath(@xml, "//point[@x > 2]/@y") == ["4", "6"]
  end

  test "access" do
    assert @xml["points/point[3]"] == ~XML[<point x="5" y="6"/>]
    assert @xml["points"]["point[3]"] == ~XML[<point x="5" y="6"/>]
    assert @xml["points/point[3]/@x"] == "5"
    assert @xml["//string/text()"] == ["foo", "bar"]
    assert Enum.map(@xml["//point"], & &1["@x"]) == ["1", "3", "5"]
    assert @xml["//point[2]"]["@y"] == "4"
  end

  test "inspect" do
    xml = ~XML[<string>bar</string>]
    assert inspect(xml) == ~s'~XML[<string>bar</string>]'
  end

  defmodule Person do
    @derive {XML.Encoder, {:person, [:gender], [:name, :email]}}

    defstruct [:name, :gender, :email]
  end

  defimpl XML.Encoder, for: URI do
    def element(uri), do: to_charlist(to_string(uri))
  end

  defimpl XML.Encoder, for: DateTime do
    def element(datetime), do: to_charlist(DateTime.to_unix(datetime))
  end

  test "deriving" do
    john = %Person{gender: :male, name: "John", email: "john@example.com"}

    assert XML.new({:people, [john]}) == ~XML'''
           <people>
             <person gender="male">
               <name>John</name>
               <email>john@example.com</email>
             </person>
           </people>
           '''

    assert XML.new(
             {:logs, [lang: :en],
              [
                {:log, [datetime: ~U[2025-12-21T00:00:00Z]],
                 [{:uri, [], URI.new!("localhost")}, {:user, "wigny"}]}
              ]}
           ) == ~XML'''
           <logs lang="en">
             <log datetime="1766275200">
               <uri>localhost</uri>
               <user>wigny</user>
             </log>
           </logs>
           '''
  end
end
