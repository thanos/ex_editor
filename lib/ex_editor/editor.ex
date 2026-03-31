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
        def on_event(:handle_change, {old_content, new_content}, editor) do
          IO.puts("Content changed from '\#{old_content}' to '\#{new_content}'")
          {:ok, editor}
        end

        @impl true
        def on_event(_event, _payload, editor), do: {:ok, editor}
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

  defstruct [:document, :plugins, :highlighter, :options, metadata: %{}]

  @type t :: %__MODULE__{
          document: Document.t(),
          plugins: list(module()),
          highlighter: module() | nil,
          metadata: map(),
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
      metadata: %{},
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
  Stores metadata in the editor for plugin use.

  ## Examples

      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> editor = ExEditor.Editor.put_metadata(editor, :my_plugin, %{state: :active})
      iex> ExEditor.Editor.get_metadata(editor, :my_plugin)
      %{state: :active}
  """
  @spec put_metadata(t(), atom(), term()) :: t()
  def put_metadata(%__MODULE__{metadata: metadata} = editor, key, value) do
    %{editor | metadata: Map.put(metadata, key, value)}
  end

  @doc """
  Gets metadata from the editor.

  Returns `nil` if the key doesn't exist.

  ## Examples

      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> ExEditor.Editor.get_metadata(editor, :missing)
      nil

      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> editor = ExEditor.Editor.put_metadata(editor, :key, "value")
      iex> ExEditor.Editor.get_metadata(editor, :key)
      "value"
  """
  @spec get_metadata(t(), atom()) :: term() | nil
  def get_metadata(%__MODULE__{metadata: metadata}, key) do
    Map.get(metadata, key)
  end

  @doc """
  Clears a metadata key from the editor.

  ## Examples

      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> editor = ExEditor.Editor.put_metadata(editor, :key, "value")
      iex> editor = ExEditor.Editor.clear_metadata(editor, :key)
      iex> ExEditor.Editor.get_metadata(editor, :key)
      nil
  """
  @spec clear_metadata(t(), atom()) :: t()
  def clear_metadata(%__MODULE__{metadata: metadata} = editor, key) do
    %{editor | metadata: Map.delete(metadata, key)}
  end

  @doc """
  Sets the content of the editor and notifies plugins.

  Returns `{:ok, updated_editor}` on success or `{:error, reason}` on failure.

  Plugins receive `:before_change` and `:handle_change` events.
  - `:before_change` - Called before the document is updated. Plugins can reject changes.
  - `:handle_change` - Called after the document is updated. Plugins react to changes.

  ## Examples

      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> {:ok, editor} = ExEditor.Editor.set_content(editor, "Hello\\nWorld")
      iex> ExEditor.Editor.get_content(editor)
      "Hello\\nWorld"

      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> {:error, :invalid_content} = ExEditor.Editor.set_content(editor, nil)
  """
  @spec set_content(t(), String.t()) :: {:ok, t()} | {:error, term()}
  def set_content(%__MODULE__{} = editor, content) when is_binary(content) do
    old_content = get_content(editor)

    with {:ok, editor} <- notify_plugins(editor, :before_change, {old_content, content}) do
      new_document = Document.from_text(content)
      editor = %{editor | document: new_document}
      # :handle_change is reactive - always succeed after document is updated
      # Plugin errors are ignored but editor state from last successful plugin is used
      case notify_plugins(editor, :handle_change, {old_content, content}) do
        {:ok, editor} -> {:ok, editor}
        {:error, _reason} -> {:ok, editor}
      end
    end
  end

  def set_content(%__MODULE__{}, _content) do
    {:error, :invalid_content}
  end

  @doc """
  Notifies plugins of a custom event.

  Allows applications to extend the plugin system with their own events.

  ## Examples

      iex> {:ok, editor} = ExEditor.Editor.new()
      iex> {:ok, editor} = ExEditor.Editor.notify(editor, :save, %{path: "file.ex"})
      iex> editor.metadata
      %{}
  """
  @spec notify(t(), atom(), term()) :: {:ok, t()} | {:error, term()}
  def notify(%__MODULE__{} = editor, event, payload) do
    notify_plugins(editor, event, payload)
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

  defp notify_plugins(editor, event, payload) do
    Enum.reduce_while(editor.plugins, {:ok, editor}, fn plugin, {:ok, ed} ->
      notify_plugin(plugin, event, payload, ed)
    end)
  end

  defp notify_plugin(plugin, event, payload, editor) do
    if function_exported?(plugin, :on_event, 3) do
      case plugin.on_event(event, payload, editor) do
        {:ok, updated_editor} -> {:cont, {:ok, updated_editor}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    else
      {:cont, {:ok, editor}}
    end
  end
end
