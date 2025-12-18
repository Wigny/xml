defmodule XMLTest do
  use ExUnit.Case
  import XML, only: [sigil_XML: 2]

  doctest XML

  @document String.trim(File.read!("test/support/breakfast_menu.xml"))

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

    assert to_string(xml["food[2]/name"]) == "Strawberry Belgian Waffles"
    # assert (XML.to_document(xml["food[2]/name/text()"])) == "Strawberry Belgian Waffles"
  end
end
