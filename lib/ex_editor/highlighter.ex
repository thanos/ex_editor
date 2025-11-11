defmodule ExEditor.Highlighter do
  @moduledoc """
  Behaviour for syntax highlighting plugins.

  A highlighter transforms plain text into HTML with syntax highlighting
  using CSS classes for styling.

  ## Example

      defmodule MyHighlighter do
        @behaviour ExEditor.Highlighter

        @impl true
        def highlight(text) do
          # Transform text into highlighted HTML
          "<span class=\\"hl-keyword\\">def</span>"
        end

        @impl true
        def name, do: "My Language"
      end

  ## CSS Classes

  Highlighters should use these standard CSS class names:

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
