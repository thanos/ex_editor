defmodule ExEditor.Plugin do
  @moduledoc """
  Behaviour for extensible ExEditor plugins.

  Plugins hook into editor events and can validate changes, track metrics, or modify editor state.
  They provide a clean way to extend editor functionality without modifying core code.

  ## Overview

  Plugins are composable, allowing multiple plugins to act on the same events. Each plugin
  can accept or reject changes, track state, or trigger side effects. Plugins are executed
  in order during event propagation.

  ## Event System

  ### `:before_change` Events

  Called **before** editor content changes. These events are **gating** - if any plugin
  returns `{:error, reason}`, the entire change is rejected and subsequent plugins are not called.

  Use `:before_change` for:
  - **Validation** - Enforce constraints (max length, format requirements)
  - **Preventing invalid states** - Reject changes that would break invariants

  The payload is `{old_content, new_content}` where both are complete document strings.

  ### `:handle_change` Events

  Called **after** editor content successfully changed. These events are **reactive** -
  errors returned by plugins during `:handle_change` are logged but do not affect the change.
  Subsequent plugins continue executing even if one fails.

  Use `:handle_change` for:
  - **Tracking metrics** - Record change history, audit logs
  - **Derived state** - Update related data based on new content
  - **Side effects** - Notify external systems, trigger auto-save

  The payload is `{old_content, new_content}` with the guarantee that the change
  succeeded at the editor level.

  ## Basic Example: Content Validation

      defmodule MyApp.Plugins.MaxLength do
        @behaviour ExEditor.Plugin

        alias ExEditor.Editor

        @max_length 10_000

        @impl true
        def on_event(:before_change, {_old, new}, editor) do
          if String.length(new) > @max_length do
            {:error, :content_too_long}
          else
            {:ok, editor}
          end
        end

        @impl true
        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

  ## Intermediate Example: Change Tracking

      defmodule MyApp.Plugins.ChangeTracker do
        @behaviour ExEditor.Plugin

        alias ExEditor.Editor

        @impl true
        def on_event(:before_change, {_old, _new}, editor) do
          {:ok, editor}
        end

        @impl true
        def on_event(:handle_change, {old, new}, editor) do
          change_count = Editor.get_metadata(editor, :change_count) || 0

          editor
          |> Editor.put_metadata(:change_count, change_count + 1)
          |> Editor.put_metadata(:last_change, %{
               timestamp: System.os_time(:millisecond),
               from_length: String.length(old),
               to_length: String.length(new),
               delta: String.length(new) - String.length(old)
             })
          |> then(&{:ok, &1})
        end

        @impl true
        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

  ## Advanced Example: Format Enforcement

      defmodule MyApp.Plugins.JSONFormatter do
        @behaviour ExEditor.Plugin

        alias ExEditor.Editor

        @impl true
        def on_event(:before_change, {_old, new}, editor) do
          case validate_json(new) do
            {:ok, _} -> {:ok, editor}
            {:error, reason} -> {:error, {:invalid_json, reason}}
          end
        end

        @impl true
        def on_event(:handle_change, {_old, new}, editor) do
          # Format and store pretty-printed version in metadata
          case Jason.decode(new) do
            {:ok, decoded} ->
              formatted = Jason.encode!(decoded, pretty: true)
              {:ok, Editor.put_metadata(editor, :formatted_preview, formatted)}

            {:error, _} ->
              {:ok, editor}
          end
        end

        @impl true
        def on_event(_event, _payload, editor), do: {:ok, editor}

        defp validate_json(text) do
          case Jason.decode(text) do
            {:ok, decoded} -> {:ok, decoded}
            {:error, reason} -> {:error, reason}
          end
        end
      end

  ## Advanced Example: Syntax Validation with Error Tracking

      defmodule MyApp.Plugins.SyntaxChecker do
        @behaviour ExEditor.Plugin

        alias ExEditor.Editor

        @impl true
        def on_event(:before_change, {_old, _new}, editor) do
          {:ok, editor}
        end

        @impl true
        def on_event(:handle_change, {_old, new}, editor) do
          case check_syntax(new) do
            {:ok, diagnostics} ->
              {:ok, Editor.put_metadata(editor, :syntax_diagnostics, diagnostics)}

            {:error, reason} ->
              {:ok, Editor.put_metadata(editor, :syntax_error, reason)}
          end
        end

        @impl true
        def on_event(_event, _payload, editor), do: {:ok, editor}

        defp check_syntax(text) do
          # Example: check if Elixir code compiles
          case Code.string_to_quoted(text) do
            {:ok, _ast} ->
              {:ok, []}

            {:error, {_line, message, _token}} ->
              {:error, message}
          end
        end
      end

  ## Plugin Composition

  Plugins execute in order, allowing composition:

      editor = ExEditor.Editor.new(
        content: "def hello, do: :world",
        plugins: [
          MyApp.Plugins.MaxLength,        # Validates length
          MyApp.Plugins.SyntaxChecker,    # Validates syntax
          MyApp.Plugins.ChangeTracker     # Tracks metrics
        ]
      )

  If MaxLength rejects a change, SyntaxChecker and ChangeTracker never run.
  If SyntaxChecker errors during `:handle_change`, its error is logged but
  ChangeTracker continues.

  ## Error Handling

  ### During `:before_change`

  Return `{:error, reason}` to reject the change. The reason can be any term:

      {:error, :content_too_long}
      {:error, {:invalid_json, \"Unexpected token\"}}
      {:error, \"Custom message for UI\"}

  The change is completely rejected - the editor content doesn't update.

  ### During `:handle_change`

  Return `{:error, reason}` to signal a problem, but the change has already succeeded.
  The error is logged and subsequent plugins continue. Use this for non-critical failures:

      {:error, :sync_failed}  # Log it, continue with next plugin
      {:error, \"Could not notify external service\"}

  Best practice: catch errors during `:handle_change` with try/catch and return
  `{:ok, editor}` to ensure plugin chains don't break.

  ## Best Practices

  1. **Separate Concerns**: One plugin per responsibility (validation, tracking, etc.)

  2. **Use Metadata Judiciously**: Store computed state in editor metadata for access
     by other plugins, but avoid storing full content duplicates.

  3. **Handle Errors Defensively**: In `:handle_change`, always wrap external calls:

         case fetch_from_api(new) do
           {:ok, response} ->
             {:ok, Editor.put_metadata(editor, :api_response, response)}
           {:error, _} ->
             # Non-critical failure, don't halt the plugin chain
             {:ok, editor}
         end

  4. **Performance**: Plugins run on every change. Keep operations fast or debounce
     expensive work.

  5. **Idempotency**: A plugin may be called multiple times with the same event
     (e.g., during undo/redo). Design to be idempotent when possible.

  6. **Testing**: Test each plugin in isolation with various inputs:

         defmodule MyApp.Plugins.MaxLengthTest do
           use ExUnit.Case

           test \"rejects content exceeding max length\" do
             editor = ExEditor.new(content: \"short\")
             long_content = String.duplicate(\"x\", 10_001)

             assert {:error, :content_too_long} =
               MyApp.Plugins.MaxLength.on_event(:before_change, {\"short\", long_content}, editor)
           end

           test \"allows content under max length\" do
             editor = ExEditor.new(content: \"short\")
             new_content = \"still short\"

             assert {:ok, ^editor} =
               MyApp.Plugins.MaxLength.on_event(:before_change, {\"short\", new_content}, editor)
           end
         end

  ## Integration with LiveView

  Register plugins when creating editor instances:

      defmodule MyAppWeb.EditorLive do
        def mount(_params, _session, socket) do
          editor = ExEditor.new(
            content: default_code(),
            plugins: [MyApp.Plugins.MaxLength, MyApp.Plugins.ChangeTracker]
          )

          {:ok, assign(socket, :editor, editor)}
        end

        def handle_event("code_changed", %{"content" => new_code}, socket) do
          case ExEditor.Editor.set_content(socket.assigns.editor, new_code) do
            {:ok, editor} ->
              {:noreply, assign(socket, :editor, editor)}

            {:error, reason} ->
              # Plugin rejected the change - show error to user
              {:noreply, put_flash(socket, :error, "Invalid: " <> to_string(reason))}
          end
        end
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
