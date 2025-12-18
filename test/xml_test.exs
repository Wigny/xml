defmodule XMLTest do
  use ExUnit.Case
  import XML, only: [sigil_XML: 2]

  doctest XML

  @document String.trim(File.read!("test/support/bookstore.xml"))

  test "sigil_XML/2" do
    assert %XML{} = ~XML"""
           <note>
             <to>Tove</to>
             <from>Jani</from>
             <heading>Reminder</heading>
             <body>Don't forget me this weekend!</body>
           </note>
           """
  end

  test "from_document/1" do
    assert %XML{} = XML.from_document(@document)
  end

  test "to_document/1" do
    xml = XML.from_document(@document)

    assert IO.iodata_to_binary(XML.to_document(xml)) == @document
  end

  test "to_string/1" do
    xml = XML.from_document(@document)

    assert to_string(xml) == @document
  end

  test "access" do
    xml = XML.from_document(@document)

    assert to_string(xml["book[2]/title"]) == "<title lang=\"en\">Harry Potter</title>"
    assert to_string(xml["book[2]"]["title"]) == "<title lang=\"en\">Harry Potter</title>"
    assert to_string(xml["book[2]/title/text()"]) == "Harry Potter"
    assert to_string(xml["book[2]/title/@lang"]) == "en"
    assert to_string(xml["//year/text()"]) == "2005200520032003"
    assert to_string(xml["//year"]["text()"]) == "2005200520032003"
  end
end
