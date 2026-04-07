defmodule ExEditor do
  @moduledoc """
  ExEditor is a headless code editor library for Phoenix LiveView applications.

  It provides a complete editing solution with:
  - Line-based document model (`ExEditor.Document`)
  - Editor state management with undo/redo (`ExEditor.Editor`)
  - Plugin system for extensibility (`ExEditor.Plugin`)
  - Syntax highlighting support (`ExEditor.Highlighter`)
  - LiveView integration (`ExEditorWeb.LiveEditor`)

  ## Quick Start

      # Create an editor
      editor = ExEditor.Editor.new(content: "Hello, World!")

      # Update content
      {:ok, editor} = ExEditor.Editor.set_content(editor, "New content")

      # Use in LiveView
      <ExEditorWeb.LiveEditor.live_editor id="editor" editor={@editor} />

  ## Components

  - `ExEditor.Editor` - Main editor state manager
  - `ExEditor.Document` - Line-based document model
  - `ExEditor.History` - Undo/redo history management
  - `ExEditor.Plugin` - Behaviour for editor plugins
  - `ExEditor.Highlighter` - Behaviour for syntax highlighters
  - `ExEditor.LineNumbers` - Line number rendering utilities
  - `ExEditor.HighlightedLines` - Highlighted content line utilities

  ## Web Integration

  For Phoenix LiveView integration, see `ExEditorWeb` and `ExEditorWeb.LiveEditor`.

  ## Highlighters

  Built-in highlighters:
  - `ExEditor.Highlighters.Elixir` - Elixir syntax
  - `ExEditor.Highlighters.JSON` - JSON syntax
  """

  @doc """
  Creates a new editor with the given options.

  Delegates to `ExEditor.Editor.new/1`.

  ## Examples

      iex> editor = ExEditor.new()
      iex> is_struct(editor, ExEditor.Editor)
      true

      iex> editor = ExEditor.new(content: "Hello")
      iex> ExEditor.Editor.get_content(editor)
      "Hello"
  """
  @spec new(keyword()) :: ExEditor.Editor.t()
  def new(opts \\ []), do: ExEditor.Editor.new(opts)

  @doc """
  Creates a new document from text.

  Delegates to `ExEditor.Document.from_text/1`.

  ## Examples

      iex> doc = ExEditor.document_from_text("line1\\nline2")
      iex> ExEditor.Document.line_count(doc)
      2
  """
  @spec document_from_text(String.t()) :: ExEditor.Document.t()
  def document_from_text(text), do: ExEditor.Document.from_text(text)
end
