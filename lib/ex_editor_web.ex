defmodule ExEditorWeb do
  @moduledoc """
  Provides Phoenix LiveView components for ExEditor.

  This module contains the LiveView integration layer for ExEditor,
  including the `LiveEditor` component for embedding code editors
  in Phoenix LiveView applications.

  ## Quick Start

  Add the following to your LiveView:

      defmodule MyAppWeb.EditorLive do
        use MyAppWeb, :live_view
        
        def render(assigns) do
          ~H\"""
          <ExEditorWeb.LiveEditor.live_editor
            id="my-editor"
            content={@code}
            language={:elixir}
            on_change="code_changed"
          />
          \"""
        end
        
        def handle_event("code_changed", %{"content" => new_code}, socket) do
          {:noreply, assign(socket, :code, new_code)}
        end
      end

  Then in your `app.js`:

      import EditorHook from "ex_editor/hooks/editor"
      
      let liveSocket = new LiveSocket("/live", Socket, {
        hooks: { EditorHook }
      })

  And in your CSS:

      @import "ex_editor/css/editor";
  """

  @doc """
  Convenience function for importing ExEditorWeb components.

  Use in your web module:

      defmodule MyAppWeb do
        def live_editor do
          quote do
            import ExEditorWeb, only: [live_editor: 1]
          end
        end
      end
  """
  defmacro __using__(_opts) do
    quote do
      import ExEditorWeb, only: [live_editor: 1]
    end
  end
end
