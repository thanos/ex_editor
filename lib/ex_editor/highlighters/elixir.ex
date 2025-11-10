defmodule ExEditor.Highlighters.Elixir do
  @moduledoc """
  Elixir syntax highlighter.

  Highlights Elixir syntax with the following token types:
  - Keywords (def, defmodule, do, end, if, case, when, etc.)
  - Atoms (:ok, :error, :atom_name)
  - Strings (double quotes, single quotes, heredocs, sigils)
  - Module names (MyApp.User, Phoenix.LiveView)
  - Comments (# single line)
  - Numbers (integers, floats, hex, octal, binary)
  - Booleans (true, false)
  - Nil
  - Operators (|>, ++, --, ==, ===, etc.)
  - Function calls
  - Variables

  ## Example

      iex> ExEditor.Highlighters.Elixir.highlight("def hello(name), do: name")
      ~s(<span class="hl-keyword">def</span> <span class="hl-function">hello</span><span class="hl-punctuation">(</span><span class="hl-variable">name</span><span class="hl-punctuation">)</span><span class="hl-punctuation">,</span> <span class="hl-keyword">do</span><span class="hl-punctuation">:</span> <span class="hl-variable">name</span>)
  """

  @behaviour ExEditor.Highlighter

  @keywords ~w(
    def defp defmodule defmacro defmacrop defguard defguardp defstruct defimpl
    defprotocol defexception defdelegate defoverridable
    do end if unless case cond when with for try catch rescue after else
    fn receive require import alias use quote unquote super
    raise throw
  )

  @impl true
  def name, do: "Elixir"

  @impl true
  def highlight(text) do
    text
    |> tokenize()
    |> Enum.map(&format_token/1)
    |> Enum.join()
  end

  # Tokenize Elixir text into a list of {type, value} tuples
  defp tokenize(text) do
    do_tokenize(text, [])
  end

  # State machine for tokenizing Elixir
  defp do_tokenize("", acc), do: Enum.reverse(acc)

  # Whitespace
  defp do_tokenize(<<char::utf8, rest::binary>>, acc)
       when char in [?\s, ?\t, ?\n, ?\r] do
    do_tokenize(rest, [{:whitespace, <<char::utf8>>} | acc])
  end

  # Comments
  defp do_tokenize(<<"#", rest::binary>>, acc) do
    {comment, remainder} = extract_until_newline(rest, "#")
    do_tokenize(remainder, [{:comment, comment} | acc])
  end

  # Heredoc strings (triple quotes)
  defp do_tokenize(<<"\"\"\"\n", rest::binary>>, acc) do
    {string, remainder} = extract_heredoc(rest, "")
    do_tokenize(remainder, [{:string, ~s("""\n#{string}""")} | acc])
  end

  # Double quoted strings
  defp do_tokenize(<<?", rest::binary>>, acc) do
    {string, remainder} = extract_string(rest, "", ?")
    do_tokenize(remainder, [{:string, ~s("#{string}")} | acc])
  end

  # Single quoted strings (charlists)
  defp do_tokenize(<<?', rest::binary>>, acc) do
    {string, remainder} = extract_string(rest, "", ?')
    do_tokenize(remainder, [{:string, ~s('#{string}')} | acc])
  end

  # Sigils
  defp do_tokenize(<<"~", sigil::utf8, delim::utf8, rest::binary>>, acc)
       when sigil in [?s, ?S, ?c, ?C, ?r, ?R, ?w, ?W] do
    close_delim = get_closing_delimiter(delim)
    {content, remainder} = extract_until_delimiter(rest, close_delim, "")
    sigil_text = "~#{<<sigil::utf8>>}#{<<delim::utf8>>}#{content}#{<<close_delim::utf8>>}"
    do_tokenize(remainder, [{:string, sigil_text} | acc])
  end

  # Atoms with quotes
  defp do_tokenize(<<?:, ?", rest::binary>>, acc) do
    {string, remainder} = extract_string(rest, "", ?")
    do_tokenize(remainder, [{:atom, ~s(:"#{string}")} | acc])
  end

  # Atoms
  defp do_tokenize(<<?:, rest::binary>>, acc) do
    {atom, remainder} = extract_atom(rest, "")
    do_tokenize(remainder, [{:atom, ":#{atom}"} | acc])
  end

  # Module names (capitalized identifiers)
  defp do_tokenize(<<char::utf8, rest::binary>>, acc) when char >= ?A and char <= ?Z do
    {name, remainder} = extract_module_name(<<char::utf8, rest::binary>>, "")
    do_tokenize(remainder, [{:module, name} | acc])
  end

  # Multi-character operators (moved up to take precedence over numbers and single-char ops)
  defp do_tokenize(<<"|>", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "|>"} | acc])
  end

  defp do_tokenize(<<"++", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "++"} | acc])
  end

  defp do_tokenize(<<"--", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "--"} | acc])
  end

  defp do_tokenize(<<"===", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "==="} | acc])
  end

  defp do_tokenize(<<"!==", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "!=="} | acc])
  end

  defp do_tokenize(<<"==", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "=="} | acc])
  end

  defp do_tokenize(<<"!=", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "!="} | acc])
  end

  defp do_tokenize(<<"<=", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "<="} | acc])
  end

  defp do_tokenize(<<">=", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, ">="} | acc])
  end

  defp do_tokenize(<<"<>", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "<>"} | acc])
  end

  defp do_tokenize(<<"::", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "::"} | acc])
  end

  defp do_tokenize(<<"->", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "->"} | acc])
  end

  defp do_tokenize(<<"<-", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "<-"} | acc])
  end

  defp do_tokenize(<<"\\\\", rest::binary>>, acc) do
    do_tokenize(rest, [{:operator, "\\\\"} | acc])
  end

  # Numbers (hex, octal, binary, float, integer)
  defp do_tokenize(<<"0x", rest::binary>>, acc) do
    {number, remainder} = extract_hex(rest, "0x")
    do_tokenize(remainder, [{:number, number} | acc])
  end

  defp do_tokenize(<<"0o", rest::binary>>, acc) do
    {number, remainder} = extract_octal(rest, "0o")
    do_tokenize(remainder, [{:number, number} | acc])
  end

  defp do_tokenize(<<"0b", rest::binary>>, acc) do
    {number, remainder} = extract_binary(rest, "0b")
    do_tokenize(remainder, [{:number, number} | acc])
  end

  defp do_tokenize(<<char::utf8, rest::binary>>, acc)
       when char in [?-, ?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9] do
    {number, remainder} = extract_number(<<char::utf8, rest::binary>>, "")
    do_tokenize(remainder, [{:number, number} | acc])
  end

  # Single character operators and punctuation
  defp do_tokenize(<<char::utf8, rest::binary>>, acc)
       when char in [?+, ?-, ?*, ?/, ?=, ?<, ?>, ?!, ?&, ?|, ?^, ?~] do
    do_tokenize(rest, [{:operator, <<char::utf8>>} | acc])
  end

  defp do_tokenize(<<char::utf8, rest::binary>>, acc)
       when char in [?(, ?), ?[, ?], ?{, ?}, ?,, ?., ?;] do
    do_tokenize(rest, [{:punctuation, <<char::utf8>>} | acc])
  end

  # Keywords, booleans, nil, and identifiers
  defp do_tokenize(<<char::utf8, rest::binary>>, acc)
       when (char >= ?a and char <= ?z) or char == ?_ do
    {word, remainder} = extract_identifier(<<char::utf8, rest::binary>>, "")

    token =
      cond do
        word in @keywords -> {:keyword, word}
        word == "true" -> {:boolean, word}
        word == "false" -> {:boolean, word}
        word == "nil" -> {:null, word}
        # Check if it's a function call (followed by parenthesis)
        match?("(" <> _, String.trim_leading(remainder)) -> {:function, word}
        true -> {:variable, word}
      end

    do_tokenize(remainder, [token | acc])
  end

  # Module attribute
  defp do_tokenize(<<"@", rest::binary>>, acc) do
    {attr, remainder} = extract_identifier(rest, "")
    do_tokenize(remainder, [{:variable, "@#{attr}"} | acc])
  end

  # Question mark (usually for macros like unless?)
  defp do_tokenize(<<??, rest::binary>>, acc) do
    do_tokenize(rest, [{:punctuation, "?"} | acc])
  end

  # Unknown character - pass through
  defp do_tokenize(<<char::utf8, rest::binary>>, acc) do
    do_tokenize(rest, [{:unknown, <<char::utf8>>} | acc])
  end

  # Extract heredoc until closing """
  defp extract_heredoc(<<"\"\"\"\n", rest::binary>>, acc), do: {acc, rest}
  defp extract_heredoc(<<"\"\"\"", rest::binary>>, acc), do: {acc, rest}

  defp extract_heredoc(<<char::utf8, rest::binary>>, acc) do
    extract_heredoc(rest, acc <> <<char::utf8>>)
  end

  defp extract_heredoc("", acc), do: {acc, ""}

  # Extract string content until closing quote
  defp extract_string(<<quote::utf8, rest::binary>>, acc, quote), do: {acc, rest}

  # Handle escaped characters
  defp extract_string(<<?\\, char::utf8, rest::binary>>, acc, quote) do
    extract_string(rest, acc <> <<?\\, char::utf8>>, quote)
  end

  # Regular characters
  defp extract_string(<<char::utf8, rest::binary>>, acc, quote) do
    extract_string(rest, acc <> <<char::utf8>>, quote)
  end

  # End of string (unclosed)
  defp extract_string("", acc, _quote), do: {acc, ""}

  # Extract atom name
  defp extract_atom(<<char::utf8, rest::binary>>, acc)
       when (char >= ?a and char <= ?z) or (char >= ?A and char <= ?Z) or
              (char >= ?0 and char <= ?9) or char == ?_ or char == ?! or char == ?? do
    extract_atom(rest, acc <> <<char::utf8>>)
  end

  defp extract_atom(rest, acc), do: {acc, rest}

  # Extract module name (can contain dots)
  defp extract_module_name(<<char::utf8, rest::binary>>, acc)
       when (char >= ?a and char <= ?z) or (char >= ?A and char <= ?Z) or
              (char >= ?0 and char <= ?9) or char == ?_ or char == ?. do
    extract_module_name(rest, acc <> <<char::utf8>>)
  end

  defp extract_module_name(rest, acc), do: {acc, rest}

  # Extract identifier (variable, function, keyword)
  defp extract_identifier(<<char::utf8, rest::binary>>, acc)
       when (char >= ?a and char <= ?z) or (char >= ?A and char <= ?Z) or
              (char >= ?0 and char <= ?9) or char == ?_ or char == ?! or char == ?? do
    extract_identifier(rest, acc <> <<char::utf8>>)
  end

  defp extract_identifier(rest, acc), do: {acc, rest}

  # Extract number (integer or float)
  defp extract_number(<<char::utf8, rest::binary>>, acc)
       when char in [?_, ?-, ?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?., ?e, ?E, ?+] do
    extract_number(rest, acc <> <<char::utf8>>)
  end

  defp extract_number(rest, acc), do: {acc, rest}

  # Extract hex number
  defp extract_hex(<<char::utf8, rest::binary>>, acc)
       when (char >= ?0 and char <= ?9) or (char >= ?a and char <= ?f) or
              (char >= ?A and char <= ?F) or char == ?_ do
    extract_hex(rest, acc <> <<char::utf8>>)
  end

  defp extract_hex(rest, acc), do: {acc, rest}

  # Extract octal number
  defp extract_octal(<<char::utf8, rest::binary>>, acc)
       when (char >= ?0 and char <= ?7) or char == ?_ do
    extract_octal(rest, acc <> <<char::utf8>>)
  end

  defp extract_octal(rest, acc), do: {acc, rest}

  # Extract binary number
  defp extract_binary(<<char::utf8, rest::binary>>, acc)
       when char in [?0, ?1, ?_] do
    extract_binary(rest, acc <> <<char::utf8>>)
  end

  defp extract_binary(rest, acc), do: {acc, rest}

  # Extract until newline (for comments)
  defp extract_until_newline(<<?\n, rest::binary>>, acc), do: {acc, <<?\n, rest::binary>>}

  defp extract_until_newline(<<char::utf8, rest::binary>>, acc) do
    extract_until_newline(rest, acc <> <<char::utf8>>)
  end

  defp extract_until_newline("", acc), do: {acc, ""}

  # Extract until closing delimiter (for sigils)
  defp extract_until_delimiter(<<delim::utf8, rest::binary>>, delim, acc), do: {acc, rest}

  defp extract_until_delimiter(<<char::utf8, rest::binary>>, delim, acc) do
    extract_until_delimiter(rest, delim, acc <> <<char::utf8>>)
  end

  defp extract_until_delimiter("", _delim, acc), do: {acc, ""}

  # Get closing delimiter for sigils
  defp get_closing_delimiter(?(), do: ?)
  defp get_closing_delimiter(?[), do: ?]
  defp get_closing_delimiter(?{), do: ?}
  defp get_closing_delimiter(?<), do: ?>
  defp get_closing_delimiter(?|), do: ?|
  defp get_closing_delimiter(?/), do: ?/
  defp get_closing_delimiter(?"), do: ?"
  defp get_closing_delimiter(?'), do: ?'
  defp get_closing_delimiter(c), do: c

  # Format token as HTML span with CSS class
  defp format_token({:whitespace, value}), do: value
  defp format_token({:keyword, value}), do: ~s(<span class="hl-keyword">#{value}</span>)
  defp format_token({:atom, value}), do: ~s(<span class="hl-key">#{escape_html(value)}</span>)

  defp format_token({:string, value}),
    do: ~s(<span class="hl-string">#{escape_html(value)}</span>)

  defp format_token({:module, value}), do: ~s(<span class="hl-module">#{value}</span>)

  defp format_token({:comment, value}),
    do: ~s(<span class="hl-comment">#{escape_html(value)}</span>)

  defp format_token({:number, value}), do: ~s(<span class="hl-number">#{value}</span>)
  defp format_token({:boolean, value}), do: ~s(<span class="hl-boolean">#{value}</span>)
  defp format_token({:null, value}), do: ~s(<span class="hl-null">#{value}</span>)

  defp format_token({:operator, value}),
    do: ~s(<span class="hl-operator">#{escape_html(value)}</span>)

  defp format_token({:punctuation, value}),
    do: ~s(<span class="hl-punctuation">#{escape_html(value)}</span>)

  defp format_token({:function, value}),
    do: ~s(<span class="hl-function">#{value}</span>)

  defp format_token({:variable, value}),
    do: ~s(<span class="hl-variable">#{escape_html(value)}</span>)

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
