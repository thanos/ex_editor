defmodule ExEditor.Plugin do
  @moduledoc """
  Behaviour for ExEditor plugins.

  Plugins can respond to editor events and modify editor state.

  ## Built-in Events

  - `:before_change` - Before content changes (can reject)
  - `:handle_change` - After content changes

  ## Example

      defmodule MyApp.Plugins.MaxLength do
        @behaviour ExEditor.Plugin

        @max_length 1000

        @impl true
        def on_event(:before_change, {_old, new}, editor) do
          if String.length(new) > @max_length do
            {:error, :content_too_long}
          else
            {:ok, editor}
          end
        end

        @impl true
        def on_event(:handle_change, {old, new}, editor) do
          {:ok, Editor.put_metadata(editor, :last_change, %{from: old, to: new})}
        end

        @impl true
        def on_event(_event, _payload, editor), do: {:ok, editor}
      end
  """

  alias ExEditor.Editor

  @doc """
  Handles an editor event.

  ## Parameters

  - `event` - Event name (atom)
  - `payload` - Event-specific data
  - `editor` - Current editor state

  ## Returns

  - `{:ok, editor}` - Continue with (optionally modified) editor
  - `{:error, reason}` - Halt event propagation
  """
  @callback on_event(event :: atom(), payload :: term(), editor :: Editor.t()) ::
              {:ok, Editor.t()} | {:error, term()}
end
