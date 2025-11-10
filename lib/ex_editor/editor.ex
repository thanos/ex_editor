defmodule ExEditor.Editor do
  @moduledoc """
  Main editor state manager with plugin support.

  The editor manages document state and coordinates with plugins
  for features like syntax highlighting.

  ## Example

      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> {:ok, editor} = ExEditor.Editor.set_content(editor, "Hello\\nWorld")
      iex> ExEditor.Editor.get_content(editor)
      "Hello\\nWorld"

  ## Plugins

  The editor supports plugins that implement the `ExEditor.Plugin` behaviour:

      defmodule MyPlugin do
        @behaviour ExEditor.Plugin

        @impl true
        def on_content_changed(old_content, new_content) do
          IO.puts("Content changed from '\#{old_content}' to '\#{new_content}'")
        end
      end

      {:ok, editor} = ExEditor.Editor.new(plugins: [MyPlugin])

  ## Syntax Highlighting

  Set a highlighter to enable syntax highlighting:

      alias ExEditor.Highlighters.JSON

      {:ok, editor} = ExEditor.Editor.new()
      editor = ExEditor.Editor.set_highlighter(editor, JSON)
      {:ok, editor} = ExEditor.Editor.set_content(editor, ~s({"name": "John"}))

      # Get highlighted HTML
      ExEditor.Editor.get_highlighted_content(editor)
  """

  alias ExEditor.Document

  defstruct [:document, :plugins, :highlighter, :options]

  @type t :: %__MODULE__{
          document: Document.t(),
          plugins: list(module()),
          highlighter: module() | nil,
          options: keyword()
        }

  @doc """
  Creates a new editor with optional plugins and content.

  ## Options

    * `:plugins` - List of plugin modules (default: `[]`)
    * `:content` - Initial content string (default: `""`)

  ## Examples

      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> is_struct(editor, ExEditor.Editor)
      true

      iex> {:ok, editor} = ExEditor.Editor.new(plugins: [MyPlugin])
      iex> editor.plugins
      [MyPlugin]

      iex> {:ok, editor} = ExEditor.Editor.new(content: "Hello")
      iex> ExEditor.Editor.get_content(editor)
      "Hello"
  """
  @spec new(keyword()) :: {:ok, t()}
  def new(opts \\ []) do
    plugins = Keyword.get(opts, :plugins, [])
    content = Keyword.get(opts, :content, "")

    editor = %__MODULE__{
      document: Document.from_text(content),
      plugins: plugins,
      highlighter: nil,
      options: []
    }

    {:ok, editor}
  end

  @doc """
  Sets the syntax highlighter for the editor.

  ## Examples

      iex> alias ExEditor.Highlighters.JSON
      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> editor = ExEditor.Editor.set_highlighter(editor, JSON)
      iex> editor.highlighter
      ExEditor.Highlighters.JSON
  """
  @spec set_highlighter(t(), module()) :: t()
  def set_highlighter(%__MODULE__{} = editor, highlighter) do
    %{editor | highlighter: highlighter}
  end

  @doc """
  Sets the content of the editor and notifies plugins.

  Returns `{:ok, updated_editor}` on success or `{:error, reason}` on failure.

  ## Examples

      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> {:ok, editor} = ExEditor.Editor.set_content(editor, "Hello\\nWorld")
      iex> ExEditor.Editor.get_content(editor)
      "Hello\\nWorld"

      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> {:error, :invalid_content} = ExEditor.Editor.set_content(editor, nil)
  """
  @spec set_content(t(), String.t()) :: {:ok, t()} | {:error, :invalid_content}
  def set_content(%__MODULE__{} = editor, content) when is_binary(content) do
    old_content = get_content(editor)
    new_document = Document.from_text(content)

    notify_plugins(editor.plugins, :on_content_changed, [old_content, content])

    {:ok, %{editor | document: new_document}}
  end

  def set_content(%__MODULE__{}, _content) do
    {:error, :invalid_content}
  end

  @doc """
  Gets the plain text content of the editor.

  ## Examples

      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> {:ok, editor} = ExEditor.Editor.set_content(editor, "Test")
      iex> ExEditor.Editor.get_content(editor)
      "Test"
  """
  @spec get_content(t()) :: String.t()
  def get_content(%__MODULE__{document: document}) do
    Document.to_text(document)
  end

  @doc """
  Gets the syntax-highlighted HTML content if a highlighter is set.

  Returns plain text if no highlighter is configured.

  ## Examples

      iex> alias ExEditor.Highlighters.JSON
      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> editor = ExEditor.Editor.set_highlighter(editor, JSON)
      iex> {:ok, editor} = ExEditor.Editor.set_content(editor, ~s({"name": "John"}))
      iex> highlighted = ExEditor.Editor.get_highlighted_content(editor)
      iex> String.contains?(highlighted, "hl-key")
      true
  """
  @spec get_highlighted_content(t()) :: String.t()
  def get_highlighted_content(%__MODULE__{highlighter: nil} = editor) do
    get_content(editor)
  end

  def get_highlighted_content(%__MODULE__{highlighter: highlighter} = editor) do
    content = get_content(editor)
    highlighter.highlight(content)
  end

  # Notify all plugins of an event
  defp notify_plugins(plugins, event, args) do
    Enum.each(plugins, fn plugin ->
      if function_exported?(plugin, event, length(args)) do
        apply(plugin, event, args)
      end
    end)
  end
end
