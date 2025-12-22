defmodule XMLTest do
  use ExUnit.Case

  import XML, only: [sigil_XML: 2]

  doctest XML

  test "new/1" do
    assert XML.new({:point, [x: 1, y: 2], ["x"]}) == ~XML'<point x="1" y="2">x</point>'
  end

  test "parse/1" do
    assert %XML{element: element} = XML.parse("<string>foo</string>")
    assert element == {"string", [], ["foo"]}
  end

  test "to_iodata/1" do
    assert iodata = XML.to_iodata(~XML'<point x="1" y="2"/>')
    assert IO.iodata_to_binary(iodata) == ~s[<point x="1" y="2"/>]
  end

  test "attribute/1" do
    assert XML.attribute(~XML'<point x="1"/>', "x") == "1"
    assert XML.attribute(~XML'<point y="2"/>', "x") == nil
  end

  test "text/2" do
    assert XML.text(~XML'<point x="1" y="2"/>') == nil
    assert XML.text(~XML"<string>bar</string>") == "bar"
    assert XML.text(~XML"<root><a>foo</a><b>bar</b></root>") == ~w[foo bar]
  end

  test "to_string" do
    assert to_string(~XML"<string>bar</string>") == "<string>bar</string>"
  end

  test "access" do
    xml = ~XML"""
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

    assert get_in(xml, ["points", "point", Access.at(2)]) == ~XML'<point x="5" y="6"/>'

    assert get_in(xml, ["strings", "string"]) == [
             ~XML'<string>foo</string>',
             ~XML'<string>bar</string>'
           ]
  end

  test "inspect" do
    xml = ~XML[<string>bar</string>]
    assert inspect(xml) == ~s'~XML[<string>bar</string>]'
  end

  defmodule Person do
    @derive {XML.Builder, {:person, [:gender], [:name, :email]}}

    defstruct [:name, :gender, :email]
  end

  test "protocol deriving" do
    john = %Person{gender: :male, name: "John", email: "john@example.com"}

    assert XML.new(john) == ~XML'''
           <person gender="male">
             <name>John</name>
             <email>john@example.com</email>
           </person>
           '''
  end

  defimpl XML.Builder, for: URI do
    def element(uri), do: to_string(uri)
  end

  defimpl XML.Builder, for: DateTime do
    def element(datetime), do: to_string(DateTime.to_unix(datetime))
  end

  test "protocol impl" do
    assert XML.new({
             :logs,
             [lang: :en],
             [
               {
                 :log,
                 [datetime: ~U[2025-12-21T00:00:00Z]],
                 [
                   {:uri, [], [URI.new!("localhost")]},
                   {:user, [], ["wigny"]}
                 ]
               }
             ]
           }) == ~XML'''
           <logs lang="en">
             <log datetime="1766275200">
               <uri>localhost</uri>
               <user>wigny</user>
             </log>
           </logs>
           '''
  end
end
