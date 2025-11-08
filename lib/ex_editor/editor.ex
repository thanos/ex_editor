defmodule ExEditor.Editor do
  @moduledoc """
  The main editor state manager.

  Manages the document state and coordinates plugins to provide
  a headless, extensible code editing experience.
  """

  alias ExEditor.Document
  alias ExEditor.Plugin

  defstruct document: %Document{},
            plugins: [],
            options: []

  @type plugin_module :: module()
  @type t :: %__MODULE__{
          document: Document.t(),
          plugins: [plugin_module()],
          options: keyword()
        }

  @doc """
  Creates a new editor instance.

  ## Options

  - `:plugins` - List of plugin modules to enable
  - `:content` - Initial text content for the document

  ## Examples

      iex> ExEditor.Editor.new()
      %ExEditor.Editor{document: %ExEditor.Document{lines: [""]}}

      iex> ExEditor.Editor.new(content: "hello\\nworld")
      %ExEditor.Editor{document: %ExEditor.Document{lines: ["hello", "world"]}}
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    content = Keyword.get(opts, :content, "")
    plugins = Keyword.get(opts, :plugins, [])

    document =
      if content == "" do
        Document.new()
      else
        Document.from_text(content)
      end

    %__MODULE__{
      document: document,
      plugins: plugins,
      options: opts
    }
  end

  @doc """
  Updates the editor with new text content.

  This will parse the content into lines and notify all plugins
  of the document change.

  ## Examples

      iex> editor = ExEditor.Editor.new()
      iex> {:ok, updated} = ExEditor.Editor.set_content(editor, "new content")
      iex> ExEditor.Document.to_text(updated.document)
      "new content"
  """
  @spec set_content(t(), String.t()) :: {:ok, t()} | {:error, term()}
  def set_content(%__MODULE__{} = editor, content) when is_binary(content) do
    document = Document.from_text(content)
    editor = %{editor | document: document}

    # Notify plugins of change
    case notify_plugins(editor, :handle_change) do
      {:ok, updated_doc} ->
        {:ok, %{editor | document: updated_doc}}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets the current text content from the editor.

  ## Examples

      iex> editor = ExEditor.Editor.new(content: "hello\\nworld")
      iex> ExEditor.Editor.get_content(editor)
      "hello\\nworld"
  """
  @spec get_content(t()) :: String.t()
  def get_content(%__MODULE__{document: document}) do
    Document.to_text(document)
  end

  # Private Functions

  defp notify_plugins(%__MODULE__{document: document, plugins: plugins}, callback) do
    Enum.reduce_while(plugins, {:ok, document}, fn plugin_module, {:ok, doc} ->
      if function_exported?(plugin_module, callback, 2) do
        case apply(plugin_module, callback, [doc, []]) do
          {:ok, updated_doc} -> {:cont, {:ok, updated_doc}}
          {:error, _} = error -> {:halt, error}
        end
      else
        {:cont, {:ok, doc}}
      end
    end)
  end
end
