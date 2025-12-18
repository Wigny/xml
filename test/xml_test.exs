defmodule XMLTest do
  use ExUnit.Case

  import Record
  import XML, only: [sigil_XML: 2]

  doctest XML

  @document String.trim(File.read!("test/support/bookstore.xml"))

  test "sigil_XML/2" do
    assert %XML{nodes: [element]} = ~XML"""
           <note>
             <to>Tove</to>
             <from>Jani</from>
             <heading>Reminder</heading>
             <body>Don't forget me this weekend!</body>
           </note>
           """

    assert is_record(element, :xmlElement)
  end

  test "from_document/1" do
    assert %XML{nodes: [element]} = XML.from_document(@document)
    assert is_record(element, :xmlElement)
  end

  test "to_iodata/1" do
    xml = XML.from_document(@document)

    assert IO.iodata_to_binary(XML.to_iodata(xml)) == @document

    assert IO.iodata_to_binary(XML.to_iodata(xml["//title[@lang='en']"])) ==
             ~s'<title lang="en">Everyday Italian</title>' <>
               ~s'<title lang="en">Harry Potter</title>' <>
               ~s'<title lang="en">XQuery Kick Start</title>' <>
               ~s'<title lang="en">Learning XML</title>'
  end

  test "to_string/1" do
    xml = XML.from_document(@document)

    assert to_string(xml) == @document
    assert to_string(xml["book[last()]/title"]) == ~s'<title lang="en">Learning XML</title>'
    assert to_string(xml["book[last()]/title/text()"]) == "Learning XML"
    assert to_string(xml["book[last()]/title/@lang"]) == "en"
  end

  test "search/2" do
    xml = XML.from_document(@document)

    assert %XML{nodes: [node]} = XML.search(xml, "/bookstore/book[last() - 1]")
    assert is_record(node, :xmlElement)

    assert %XML{nodes: [node]} = XML.search(xml, "/bookstore/book[last()]/title/@lang")
    assert is_record(node, :xmlAttribute)

    assert %XML{nodes: nodes} = XML.search(xml, "//title[@lang]")
    assert length(nodes) == 4
    assert Enum.all?(nodes, &is_record(&1, :xmlElement))

    assert %XML{nodes: nodes} = XML.search(xml, "/bookstore/book[price>35.00]/title")
    assert length(nodes) == 2
    assert Enum.all?(nodes, &is_record(&1, :xmlElement))
  end

  test "access" do
    xml = XML.from_document(@document)

    assert to_string(xml["book[4]/title"]) == ~s'<title lang="en">Learning XML</title>'
    assert to_string(xml["book[4]"]["title"]) == ~s'<title lang="en">Learning XML</title>'
    assert to_string(xml["book[4]/title/text()"]) == "Learning XML"
    assert to_string(xml["//year/text()"]) == "2005200520032003"
    assert to_string(xml["//year[3]"]["text()"]) == "2003"
  end

  test "enumerable" do
    xml = XML.from_document(@document)

    assert Enum.map(xml["book"], &to_string(&1["year/text()"])) == ~w[2005 2005 2003 2003]
  end
end
