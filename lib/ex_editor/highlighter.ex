defmodule ExEditor.Highlighter do
  @moduledoc """
  Behaviour for syntax highlighting plugins.

  A highlighter transforms plain text into HTML with syntax highlighting
  using CSS classes for styling. Implement this behaviour to add support
  for new languages in ExEditor.

  ## Overview

  Highlighters are responsible for tokenizing and styling source code.
  They take plain text and return HTML with semantic CSS classes that
  ExEditor uses for styling. The highlighting is performed server-side
  during the debounce window, ensuring accurate syntax highlighting
  without impacting typing performance.

  ## Standard CSS Classes

  Use these standardized CSS class names for consistent styling across
  all highlighters:

  - `hl-keyword` - Language keywords (def, if, while, etc.)
  - `hl-string` - String literals
  - `hl-number` - Numeric literals
  - `hl-boolean` - Boolean values (true/false)
  - `hl-null` - Null/nil values
  - `hl-key` - Object/map keys
  - `hl-punctuation` - Brackets, braces, commas, etc.
  - `hl-comment` - Comments
  - `hl-operator` - Operators (+, -, *, etc.)
  - `hl-function` - Function names
  - `hl-variable` - Variables

  ## Basic Example

      defmodule MyApp.Highlighters.Ruby do
        @behaviour ExEditor.Highlighter

        @impl true
        def highlight(text) do
          text
          |> tokenize()
          |> Enum.map_join(&format_token/1)
        end

        @impl true
        def name, do: "Ruby"

        defp tokenize(text) do
          # Implement your tokenization logic here
          # Return list of {type, value} tuples
        end

        defp format_token({:keyword, "def"}),
          do: ~s(<span class="hl-keyword">def</span>)
        defp format_token({:string, value}),
          do: ~s(<span class="hl-string">\#{value}</span>)
      end

  ## Advanced Example: Custom Language Highlighter

      defmodule MyApp.Highlighters.CustomLang do
        @behaviour ExEditor.Highlighter

        @keywords ~w(fn if then else match do end)

        @impl true
        def highlight(text) do
          text
          |> tokenize()
          |> Enum.map_join("", &format_token/1)
        end

        @impl true
        def name, do: "CustomLang"

        defp tokenize(text) do
          # Use your preferred tokenization approach
          # This example uses a simple regex-based approach
          tokenize_chars(text, [], [])
        end

        defp tokenize_chars("", acc, tokens), do: Enum.reverse(acc ++ tokens)

        defp tokenize_chars(<<"#" :: utf8, rest :: binary>>, acc, tokens) do
          {comment, remainder} = extract_comment(rest)
          tokenize_chars(remainder, [{:comment, "#" <> comment} | acc], tokens)
        end

        defp tokenize_chars(<<"\\\"" :: utf8, rest :: binary>>, acc, tokens) do
          {string, remainder} = extract_string(rest, "")
          tokenize_chars(remainder, [{:string, "\\"" <> string <> "\\""} | acc], tokens)
        end

        defp tokenize_chars(<<char :: utf8, rest :: binary>>, acc, tokens)
             when char in [?\\s, ?\\n, ?\\t, ?\\r] do
          tokenize_chars(rest, [{:whitespace, <<char :: utf8>>} | acc], tokens)
        end

        defp tokenize_chars(text, acc, tokens) do
          case extract_identifier(text, "") do
            {identifier, rest} ->
              token_type = if identifier in @keywords, do: :keyword, else: :variable
              tokenize_chars(rest, [{token_type, identifier} | acc], tokens)

            nil ->
              {char, rest} = String.split_at(text, 1)
              tokenize_chars(rest, [{:unknown, char} | acc], tokens)
          end
        end

        defp extract_comment(text) do
          case String.split(text, "\\n", parts: 2) do
            [comment, rest] -> {comment, rest}
            [comment] -> {comment, ""}
          end
        end

        defp extract_string("", acc), do: {acc, ""}
        defp extract_string(<<"\\\"" :: utf8, rest :: binary>>, acc), do: {acc, rest}
        defp extract_string(text, acc) do
          {char, rest} = String.split_at(text, 1)
          extract_string(rest, acc <> char)
        end

        defp extract_identifier(text, acc) do
          case Regex.match?(~r/[a-zA-Z0-9_]/, text) do
            true ->
              {char, rest} = String.split_at(text, 1)
              extract_identifier(rest, acc <> char)

            false ->
              case acc do
                "" -> nil
                _ -> {acc, text}
              end
          end
        end

        defp format_token({:whitespace, value}), do: value
        defp format_token({:keyword, value}),
          do: ~s(<span class="hl-keyword">\#{value}</span>)
        defp format_token({:string, value}),
          do: ~s(<span class="hl-string">\#{value}</span>)
        defp format_token({:comment, value}),
          do: ~s(<span class="hl-comment">\#{value}</span>)
        defp format_token({:variable, value}),
          do: ~s(<span class="hl-variable">\#{value}</span>)
        defp format_token({:unknown, value}), do: value
      end

  ## Integration with ExEditor

  Register your highlighter when creating an editor:

      editor =
        ExEditor.new(content: "puts 'Hello'")
        |> ExEditor.Editor.set_highlighter(MyApp.Highlighters.Ruby)

  Or specify it in the LiveView component:

      <ExEditorWeb.LiveEditor.live_editor
        id="code-editor"
        content={@code}
        language={:ruby}
      />

  ## Best Practices

  1. **HTML Escaping**: Always escape special HTML characters in token values
  2. **Multi-line Support**: Handle strings, comments, and heredocs that span multiple lines
  3. **Performance**: Keep tokenization fast - it runs on every content change
  4. **Consistency**: Use standard CSS classes from the list above
  5. **Testing**: Include tests for edge cases (empty input, special chars, etc.)

  ## Built-in Highlighters

  ExEditor comes with highlighters for:

  - `ExEditor.Highlighters.Elixir` - Elixir syntax
  - `ExEditor.Highlighters.JSON` - JSON format

  Both can be used as reference implementations.
  """

  @doc """
  Highlights the given text and returns HTML-safe string with CSS classes.
  """
  @callback highlight(text :: String.t()) :: String.t()

  @doc """
  Returns the human-readable name of the language this highlighter supports.
  """
  @callback name() :: String.t()
end
