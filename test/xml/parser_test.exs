defmodule XML.ParserTest do
  use ExUnit.Case

  test "invalid XML document" do
    assert_raise ArgumentError, "invalid XML document", fn ->
      XML.parse("<unclosed>")
    end

    assert_raise ArgumentError, "invalid XML document", fn ->
      XML.parse("</closing-without-opening>")
    end

    assert_raise ArgumentError, "invalid XML document", fn ->
      XML.parse("<mismatched></tag>")
    end
  end

  test "forbid internal entity expansion" do
    # Simple internal entity
    xml_with_entity = """
    <?xml version="1.0"?>
    <!DOCTYPE test [
      <!ENTITY greeting "Hello World">
    ]>
    <root>&greeting;</root>
    """

    assert_raise ArgumentError, "invalid XML document", fn ->
      XML.parse(xml_with_entity)
    end

    # Billion laughs attack - entities expand exponentially
    xml_bomb = """
    <?xml version="1.0"?>
    <!DOCTYPE lolz [
      <!ENTITY lol "lol">
      <!ENTITY lol2 "&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;">
      <!ENTITY lol3 "&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;">
    ]>
    <root>&lol3;</root>
    """

    assert_raise ArgumentError, "invalid XML document", fn ->
      XML.parse(xml_bomb)
    end
  end

  test "forbid external entity expansion" do
    # XXE attack attempting to read a local file
    xxe_file_attack = """
    <?xml version="1.0"?>
    <!DOCTYPE root [
      <!ENTITY xxe SYSTEM "file:///etc/passwd">
    ]>
    <root>&xxe;</root>
    """

    assert_raise ArgumentError, "invalid XML document", fn ->
      XML.parse(xxe_file_attack)
    end

    # XXE attack with HTTP URL
    xxe_http_attack = """
    <?xml version="1.0"?>
    <!DOCTYPE root [
      <!ENTITY xxe SYSTEM "http://malicious.com/data">
    ]>
    <root>&xxe;</root>
    """

    assert_raise ArgumentError, "invalid XML document", fn ->
      XML.parse(xxe_http_attack)
    end
  end
end
