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
end
