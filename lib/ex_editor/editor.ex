defmodule ExEditor.Editor do
  @moduledoc """
  Main editor state manager with plugin support, undo/redo history, and metadata.

  The editor manages document state and coordinates with plugins
  for features like syntax highlighting, content validation, and change tracking.

  ## Example

      editor = ExEditor.Editor.new()
      {:ok, editor} = ExEditor.Editor.set_content(editor, "Hello\\nWorld")
      ExEditor.Editor.get_content(editor)
      # => "Hello\\nWorld"

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

      editor = ExEditor.Editor.new(plugins: [MyPlugin])

  ## Undo/Redo

  The editor maintains a bounded history of document snapshots for undo/redo:

      editor = ExEditor.Editor.new(content: "first")
      {:ok, editor} = ExEditor.Editor.set_content(editor, "second")
      {:ok, editor} = ExEditor.Editor.undo(editor)
      ExEditor.Editor.get_content(editor)
      # => "first"

  ## Metadata

  Plugins can store arbitrary state in the editor's metadata map:

      editor = ExEditor.Editor.put_metadata(editor, :word_count, 42)
      ExEditor.Editor.get_metadata(editor, :word_count)
      # => 42

  ## Syntax Highlighting

  Set a highlighter to enable syntax highlighting:

      alias ExEditor.Highlighters.JSON

      editor = ExEditor.Editor.new()
      editor = ExEditor.Editor.set_highlighter(editor, JSON)
      {:ok, editor} = ExEditor.Editor.set_content(editor, ~s({"name": "John"}))

      # Get highlighted HTML
      ExEditor.Editor.get_highlighted_content(editor)
  """

  alias ExEditor.Document
  alias ExEditor.History

  defstruct [
    :document,
    :plugins,
    :highlighter,
    :options,
    metadata: %{},
    history: History.new(),
    search: nil
  ]

  @type t :: %__MODULE__{
          document: Document.t(),
          plugins: list(module()),
          highlighter: module() | nil,
          metadata: map(),
          history: History.t(),
          search: map() | nil,
          options: keyword()
        }

  @doc """
  Creates a new editor with optional plugins and content.

  ## Options

    * `:plugins` - List of plugin modules (default: `[]`)
    * `:content` - Initial content string (default: `""`)

  ## Examples

      iex> editor = ExEditor.Editor.new()
      iex> is_struct(editor, ExEditor.Editor)
      true

      iex> editor = ExEditor.Editor.new(plugins: [MyPlugin])
      iex> editor.plugins
      [MyPlugin]

      iex> editor = ExEditor.Editor.new(content: "Hello")
      iex> ExEditor.Editor.get_content(editor)
      "Hello"
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    plugins = Keyword.get(opts, :plugins, [])
    content = Keyword.get(opts, :content, "")

    validate_plugins!(plugins)

    document = Document.from_text(content)
    history = History.push(History.new(), document)

    %__MODULE__{
      document: document,
      plugins: plugins,
      highlighter: nil,
      metadata: %{},
      history: history,
      search: nil,
      options: []
    }
  end

  defp validate_plugins!(plugins) do
    Enum.each(plugins, fn plugin ->
      unless function_exported?(plugin, :on_event, 3) do
        raise ArgumentError,
              "plugin #{inspect(plugin)} must implement on_event/3 callback"
      end
    end)
  end

  @doc """
  Sets the syntax highlighter for the editor.

  ## Examples

      iex> alias ExEditor.Highlighters.JSON
      iex> editor = ExEditor.Editor.new()
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

      iex> editor = ExEditor.Editor.new()
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

      iex> editor = ExEditor.Editor.new()
      iex> ExEditor.Editor.get_metadata(editor, :missing)
      nil

      iex> editor = ExEditor.Editor.new()
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

      iex> editor = ExEditor.Editor.new()
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

      iex> editor = ExEditor.Editor.new()
      iex> {:ok, editor} = ExEditor.Editor.set_content(editor, "Hello\\nWorld")
      iex> ExEditor.Editor.get_content(editor)
      "Hello\\nWorld"

      iex> editor = ExEditor.Editor.new()
      iex> {:error, :invalid_content} = ExEditor.Editor.set_content(editor, nil)
  """
  @spec set_content(t(), String.t()) :: {:ok, t()} | {:error, term()}
  def set_content(%__MODULE__{} = editor, content) when is_binary(content) do
    old_content = get_content(editor)

    with {:ok, editor} <- notify_plugins_before_change(editor, {old_content, content}) do
      new_document = Document.from_text(content)
      history = History.push(editor.history, new_document)
      editor = %{editor | document: new_document, history: history}

      case notify_plugins_handle_change(editor, {old_content, content}) do
        {:ok, editor} -> {:ok, editor}
        {:error, _reason, editor} -> {:ok, editor}
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

      iex> editor = ExEditor.Editor.new()
      iex> {:ok, editor} = ExEditor.Editor.notify(editor, :save, %{path: "file.ex"})
      iex> editor.metadata
      %{}
  """
  @spec notify(t(), atom(), term()) :: {:ok, t()} | {:error, term()}
  def notify(%__MODULE__{} = editor, event, payload) do
    Enum.reduce_while(editor.plugins, {:ok, editor}, fn plugin, {:ok, ed} ->
      notify_plugin(plugin, event, payload, ed)
    end)
  end

  @doc """
  Gets the plain text content of the editor.

  ## Examples

      iex> editor = ExEditor.Editor.new()
      iex> {:ok, editor} = ExEditor.Editor.set_content(editor, "Test")
      iex> ExEditor.Editor.get_content(editor)
      "Test"
  """
  @spec get_content(t()) :: String.t()
  def get_content(%__MODULE__{document: document}) do
    Document.to_text(document)
  end

  @doc """
  Applies a text diff operation to content.

  Takes the current content string and a diff specified by `from`, `to`, and `text`:
  - `from` - start index of changed region (0-based, character index)
  - `to` - end index (exclusive) of changed region in the old content
  - `text` - replacement text for that region

  Returns `{:ok, new_content}` or `{:error, :out_of_bounds}` if positions are invalid.

  ## Examples

      iex> ExEditor.Editor.apply_diff("hello", 1, 4, "a")
      {:ok, "halo"}

      iex> ExEditor.Editor.apply_diff("hello", 5, 5, " world")
      {:ok, "hello world"}

      iex> ExEditor.Editor.apply_diff("hello", 3, 1, "x")
      {:error, :out_of_bounds}

      iex> ExEditor.Editor.apply_diff("hi", 10, 11, "x")
      {:error, :out_of_bounds}
  """
  @spec apply_diff(String.t(), non_neg_integer(), non_neg_integer(), String.t()) ::
          {:ok, String.t()} | {:error, :out_of_bounds}
  def apply_diff(content, from, to, inserted)
      when is_binary(content) and
             is_integer(from) and is_integer(to) and is_binary(inserted) do
    len = String.length(content)

    if from < 0 or to < from or to > len do
      {:error, :out_of_bounds}
    else
      prefix = String.slice(content, 0, from)
      suffix = String.slice(content, to, len - to)
      {:ok, prefix <> inserted <> suffix}
    end
  end

  def apply_diff(_content, _from, _to, _inserted) do
    {:error, :out_of_bounds}
  end

  @doc """
  Gets the syntax-highlighted HTML content if a highlighter is set.

  Returns plain text if no highlighter is configured.

  ## Examples

      iex> alias ExEditor.Highlighters.JSON
      iex> editor = ExEditor.Editor.new()
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

  # Undo/Redo

  @doc """
  Undoes the last content change.

  Returns `{:ok, editor}` with the previous content, or `{:error, :no_history}` if nothing to undo.

  After restoring the previous document, plugins are notified with a `:handle_change` event
  containing `{old_content, new_content}`. The search state is also cleared.

  ## Examples

      iex> editor = ExEditor.Editor.new(content: "first")
      iex> {:ok, editor} = ExEditor.Editor.set_content(editor, "second")
      iex> {:ok, editor} = ExEditor.Editor.undo(editor)
      iex> ExEditor.Editor.get_content(editor)
      "first"
  """
  @spec undo(t()) :: {:ok, t()} | {:error, :no_history}
  def undo(%__MODULE__{history: history} = editor) do
    case History.undo(history) do
      {:ok, document, history} ->
        old_content = get_content(editor)
        editor = %{editor | document: document, history: history, search: nil}
        new_content = get_content(editor)

        case notify_plugins_handle_change(editor, {old_content, new_content}) do
          {:ok, editor} -> {:ok, editor}
          {:error, _reason, editor} -> {:ok, editor}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Redoes the last undone change.

  Returns `{:ok, editor}` with the restored content, or `{:error, :no_redo}` if nothing to redo.

  After restoring the document, plugins are notified with a `:handle_change` event
  containing `{old_content, new_content}`. The search state is also cleared.

  ## Examples

      iex> editor = ExEditor.Editor.new(content: "first")
      iex> {:ok, editor} = ExEditor.Editor.set_content(editor, "second")
      iex> {:ok, editor} = ExEditor.Editor.undo(editor)
      iex> {:ok, editor} = ExEditor.Editor.redo(editor)
      iex> ExEditor.Editor.get_content(editor)
      "second"
  """
  @spec redo(t()) :: {:ok, t()} | {:error, :no_redo}
  def redo(%__MODULE__{history: history} = editor) do
    case History.redo(history) do
      {:ok, document, history} ->
        old_content = get_content(editor)
        editor = %{editor | document: document, history: history, search: nil}
        new_content = get_content(editor)

        case notify_plugins_handle_change(editor, {old_content, new_content}) do
          {:ok, editor} -> {:ok, editor}
          {:error, _reason, editor} -> {:ok, editor}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Checks if undo is available.

  ## Examples

      iex> editor = ExEditor.Editor.new()
      iex> ExEditor.Editor.can_undo?(editor)
      false

      iex> editor = ExEditor.Editor.new(content: "first")
      iex> {:ok, editor} = ExEditor.Editor.set_content(editor, "second")
      iex> ExEditor.Editor.can_undo?(editor)
      true
  """
  @spec can_undo?(t()) :: boolean()
  def can_undo?(%__MODULE__{history: history}), do: History.can_undo?(history)

  @doc """
  Checks if redo is available.

  ## Examples

      iex> editor = ExEditor.Editor.new()
      iex> ExEditor.Editor.can_redo?(editor)
      false
  """
  @spec can_redo?(t()) :: boolean()
  def can_redo?(%__MODULE__{history: history}), do: History.can_redo?(history)

  defp notify_plugins_before_change(editor, payload) do
    Enum.reduce_while(editor.plugins, {:ok, editor}, fn plugin, {:ok, ed} ->
      notify_plugin(plugin, :before_change, payload, ed)
    end)
  end

  defp notify_plugins_handle_change(editor, payload) do
    Enum.reduce_while(editor.plugins, {:ok, editor}, fn plugin, {:ok, ed} ->
      case notify_plugin_with_fallback(plugin, :handle_change, payload, ed) do
        {:ok, updated_editor} -> {:cont, {:ok, updated_editor}}
        {:error, reason} -> {:halt, {:error, reason, ed}}
      end
    end)
  end

  defp notify_plugin(plugin, event, payload, editor) do
    case plugin.on_event(event, payload, editor) do
      {:ok, updated_editor} -> {:cont, {:ok, updated_editor}}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  defp notify_plugin_with_fallback(plugin, event, payload, editor) do
    plugin.on_event(event, payload, editor)
  end
end
