defmodule ExEditor.Plugin do
  @moduledoc """
  Behaviour for ExEditor plugins.

  Plugins extend the editor with additional functionality like:
  - Line numbering
  - Syntax highlighting
  - Autocomplete
  - Custom decorations

  ## Example

  Define a plugin by implementing this behaviour:

      defmodule MyEditor.Plugins.MyPlugin do
        @behaviour ExEditor.Plugin

        @impl true
        def render(document, _opts) do
          # Return HEEx template or HTML string
        end

        @impl true
        def handle_change(document, _opts) do
          # React to document changes
          {:ok, document}
        end
      end
  """

  alias ExEditor.Document

  @doc """
  Renders the plugin's UI contribution.

  Receives the current document and plugin-specific options.
  Returns an HEEx template or HTML string to be rendered.
  """
  @callback render(document :: Document.t(), opts :: keyword()) :: Phoenix.LiveView.Rendered.t()

  @doc """
  Handles document changes.

  Called whenever the document changes, allowing plugins to:
  - Update internal state
  - Trigger side effects
  - Transform the document

  Returns `{:ok, document}` or `{:error, reason}`.
  """
  @callback handle_change(document :: Document.t(), opts :: keyword()) ::
              {:ok, Document.t()} | {:error, term()}
end
