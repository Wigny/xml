defmodule XML.Parser do
  @moduledoc false

  def parse(xml) do
    case :xmerl_sax_parser.stream(xml, event_fun: &handle_parse_event/3, event_state: []) do
      {:ok, [element], _rest} ->
        element

      {:fatal_error, _parser_state, _reason, _location, _event_state} ->
        raise ArgumentError, "invalid XML document"
    end
  end

  defp handle_parse_event(
         {:startElement, _uri, _local_name, {prefix, name}, attributes},
         _location,
         ancestor_elements
       ) do
    [{normalize_name(prefix, name), normalize_attributes(attributes), []} | ancestor_elements]
  end

  defp handle_parse_event(
         {:endElement, _uri, _local_name, _qualified_name},
         _location,
         [current_element]
       ) do
    [current_element]
  end

  defp handle_parse_event(
         {:endElement, _uri, _local_name, _qualified_name},
         _location,
         [current_element, parent_element | ancestor_elements]
       ) do
    [append_child(parent_element, current_element) | ancestor_elements]
  end

  defp handle_parse_event({:characters, ~c""}, _location, ancestor_elements) do
    ancestor_elements
  end

  defp handle_parse_event({:characters, chars}, _location, [current_element | ancestor_elements]) do
    [append_child(current_element, to_string(chars)) | ancestor_elements]
  end

  defp handle_parse_event({:internalEntityDecl, _name, _value}, _location, _state) do
    throw({:fatal_error, ~c"Forbid internal entity expansion"})
  end

  defp handle_parse_event({:externalEntityDecl, _name, _public_id, _system_id}, _location, _state) do
    throw({:fatal_error, ~c"Forbid external entity expansion"})
  end

  defp handle_parse_event(_event, _arg, state) do
    state
  end

  defp normalize_name(~c"", name) do
    to_string(name)
  end

  defp normalize_name(prefix, name) do
    Enum.join([prefix, name], ":")
  end

  defp normalize_attributes(attributes) do
    for {_uri, prefix, name, value} <- attributes do
      {normalize_name(prefix, name), to_string(value)}
    end
  end

  defp append_child({tag, attributes, children}, child) do
    {tag, attributes, children ++ [child]}
  end
end
