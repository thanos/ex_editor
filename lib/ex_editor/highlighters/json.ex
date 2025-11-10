defmodule ExEditor.Highlighters.JSON do
  @moduledoc """
  JSON syntax highlighter.

  Highlights JSON syntax with the following token types:
  - Strings (including escape sequences)
  - Numbers (integers and floats)
  - Booleans (true/false)
  - Null values
  - Object keys
  - Punctuation (braces, brackets, colons, commas)

  ## Example

      iex> ExEditor.Highlighters.JSON.highlight(~s({"name": "John"}))
      ~s(<span class="hl-punctuation">{</span><span class="hl-key">"name"</span><span class="hl-punctuation">:</span> <span class="hl-string">"John"</span><span class="hl-punctuation">}</span>)
  """

  @behaviour ExEditor.Highlighter

  @impl true
  def name, do: "JSON"

  @impl true
  def highlight(text) do
    text
    |> tokenize()
    |> Enum.map(&format_token/1)
    |> Enum.join()
  end

  # Tokenize JSON text into a list of {type, value} tuples
  defp tokenize(text) do
    do_tokenize(text, [], :start)
  end

  # State machine for tokenizing JSON
  defp do_tokenize("", acc, _state), do: Enum.reverse(acc)

  # Whitespace
  defp do_tokenize(<<char::utf8, rest::binary>>, acc, state)
       when char in [?\s, ?\t, ?\n, ?\r] do
    do_tokenize(rest, [{:whitespace, <<char::utf8>>} | acc], state)
  end

  # String start
  defp do_tokenize(<<?", rest::binary>>, acc, :start) do
    {string, remainder} = extract_string(rest, "")
    do_tokenize(remainder, [{:string, ~s("#{string}")} | acc], :start)
  end

  # Object key (string followed by colon)
  defp do_tokenize(<<?", rest::binary>>, acc, :after_brace) do
    {string, remainder} = extract_string(rest, "")
    do_tokenize(remainder, [{:key, ~s("#{string}")} | acc], :after_key)
  end

  defp do_tokenize(<<?", rest::binary>>, acc, :after_comma_in_object) do
    {string, remainder} = extract_string(rest, "")
    do_tokenize(remainder, [{:key, ~s("#{string}")} | acc], :after_key)
  end

  # Numbers
  defp do_tokenize(<<char::utf8, rest::binary>>, acc, state)
       when char in [?-, ?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9] do
    {number, remainder} = extract_number(<<char::utf8, rest::binary>>, "")
    do_tokenize(remainder, [{:number, number} | acc], state)
  end

  # Booleans
  defp do_tokenize(<<"true", rest::binary>>, acc, state) do
    do_tokenize(rest, [{:boolean, "true"} | acc], state)
  end

  defp do_tokenize(<<"false", rest::binary>>, acc, state) do
    do_tokenize(rest, [{:boolean, "false"} | acc], state)
  end

  # Null
  defp do_tokenize(<<"null", rest::binary>>, acc, state) do
    do_tokenize(rest, [{:null, "null"} | acc], state)
  end

  # Punctuation - opening brace
  defp do_tokenize(<<"{", rest::binary>>, acc, _state) do
    do_tokenize(rest, [{:punctuation, "{"} | acc], :after_brace)
  end

  # Punctuation - closing brace
  defp do_tokenize(<<"}", rest::binary>>, acc, _state) do
    do_tokenize(rest, [{:punctuation, "}"} | acc], :start)
  end

  # Punctuation - opening bracket
  defp do_tokenize(<<"[", rest::binary>>, acc, _state) do
    do_tokenize(rest, [{:punctuation, "["} | acc], :start)
  end

  # Punctuation - closing bracket
  defp do_tokenize(<<"]", rest::binary>>, acc, _state) do
    do_tokenize(rest, [{:punctuation, "]"} | acc], :start)
  end

  # Punctuation - colon (after key)
  defp do_tokenize(<<":", rest::binary>>, acc, :after_key) do
    do_tokenize(rest, [{:punctuation, ":"} | acc], :start)
  end

  # Punctuation - comma in object
  defp do_tokenize(<<",", rest::binary>>, acc, state) when state in [:start, :after_key] do
    do_tokenize(rest, [{:punctuation, ","} | acc], :after_comma_in_object)
  end

  # Punctuation - comma in array
  defp do_tokenize(<<",", rest::binary>>, acc, state) do
    do_tokenize(rest, [{:punctuation, ","} | acc], state)
  end

  # Unknown character - pass through
  defp do_tokenize(<<char::utf8, rest::binary>>, acc, state) do
    do_tokenize(rest, [{:unknown, <<char::utf8>>} | acc], state)
  end

  # Extract string content until closing quote
  defp extract_string(<<?", rest::binary>>, acc), do: {acc, rest}

  # Handle escaped characters
  defp extract_string(<<?\\, char::utf8, rest::binary>>, acc) do
    extract_string(rest, acc <> <<?\\, char::utf8>>)
  end

  # Regular characters
  defp extract_string(<<char::utf8, rest::binary>>, acc) do
    extract_string(rest, acc <> <<char::utf8>>)
  end

  # End of string (unclosed)
  defp extract_string("", acc), do: {acc, ""}

  # Extract number (integer or float)
  defp extract_number(<<char::utf8, rest::binary>>, acc)
       when char in [?-, ?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?., ?e, ?E, ?+] do
    extract_number(rest, acc <> <<char::utf8>>)
  end

  defp extract_number(rest, acc), do: {acc, rest}

  # Format token as HTML span with CSS class
  defp format_token({:whitespace, value}), do: value

  defp format_token({:string, value}),
    do: ~s(<span class="hl-string">#{escape_html(value)}</span>)

  defp format_token({:key, value}), do: ~s(<span class="hl-key">#{escape_html(value)}</span>)
  defp format_token({:number, value}), do: ~s(<span class="hl-number">#{value}</span>)
  defp format_token({:boolean, value}), do: ~s(<span class="hl-boolean">#{value}</span>)
  defp format_token({:null, value}), do: ~s(<span class="hl-null">#{value}</span>)

  defp format_token({:punctuation, value}),
    do: ~s(<span class="hl-punctuation">#{escape_html(value)}</span>)

  defp format_token({:unknown, value}), do: escape_html(value)

  # Escape HTML special characters
  defp escape_html(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end
end
