# Plugin Guide

This guide explains how to create and use plugins with ExEditor.

## Overview

Plugins extend ExEditor functionality by responding to editor events. They can:
- Validate and reject content changes
- React to content changes (auto-save, linting, etc.)
- Store custom state in editor metadata
- Handle application-defined custom events

## Plugin Behaviour

Implement the `ExEditor.Plugin` behaviour:

```elixir
@callback on_event(event :: atom(), payload :: term(), editor :: Editor.t()) ::
  {:ok, Editor.t()} | {:error, term()}
```

## Built-in Events

| Event | When | Payload | Can Reject? |
|-------|------|---------|-------------|
| `:before_change` | Before content changes | `{old_content, new_content}` | Yes |
| `:handle_change` | After content changes | `{old_content, new_content}` | No |

## Basic Plugin

```elixir
defmodule MyEditor.Plugins.Logger do
  @behaviour ExEditor.Plugin

  @impl true
  def on_event(:handle_change, {old_content, new_content}, editor) do
    IO.puts("Content changed!")
    IO.puts("  From: #{String.slice(old_content, 0, 50)}...")
    IO.puts("  To: #{String.slice(new_content, 0, 50)}...")
    {:ok, editor}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end
```

Usage:

```elixir
editor = ExEditor.Editor.new(plugins: [MyEditor.Plugins.Logger])
{:ok, editor} = ExEditor.Editor.set_content(editor, "Hello world")
# Prints: Content changed!
```

## Validation Plugin

Reject changes that don't meet criteria:

```elixir
defmodule MyEditor.Plugins.MaxLength do
  @behaviour ExEditor.Plugin

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
```

Usage:

```elixir
editor = ExEditor.Editor.new(plugins: [MyEditor.Plugins.MaxLength])

case ExEditor.Editor.set_content(editor, really_long_content) do
  {:ok, editor} -> 
    # Content accepted
    {:ok, editor}
  {:error, :content_too_long} ->
    # Content rejected - notify user
    {:error, :content_too_long}
end
```

## Stateful Plugin

Store plugin state in editor metadata:

```elixir
defmodule MyEditor.Plugins.ChangeTracker do
  @behaviour ExEditor.Plugin

  @impl true
  def on_event(:handle_change, {old, new}, editor) do
    change = %{
      timestamp: DateTime.utc_now(),
      old_length: String.length(old),
      new_length: String.length(new)
    }

    history = ExEditor.Editor.get_metadata(editor, :change_history) || []
    updated_history = [change | history] |> Enum.take(100)

    {:ok, ExEditor.Editor.put_metadata(editor, :change_history, updated_history)}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}

  # Public helper to get history
  def get_history(editor) do
    ExEditor.Editor.get_metadata(editor, :change_history) || []
  end
end
```

Usage:

```elixir
editor = ExEditor.Editor.new(plugins: [MyEditor.Plugins.ChangeTracker])
{:ok, editor} = ExEditor.Editor.set_content(editor, "Hello")
{:ok, editor} = ExEditor.Editor.set_content(editor, "Hello world")

history = MyEditor.Plugins.ChangeTracker.get_history(editor)
# [%{timestamp: ~U[...], old_length: 5, new_length: 11}, ...]
```

## Plugin Chain

Multiple plugins execute in order, forming a middleware chain. Each plugin receives the editor state from the previous plugin:

```elixir
defmodule MyEditor.Plugins.WordCounter do
  @behaviour ExEditor.Plugin

  @impl true
  def on_event(:handle_change, {_old, new}, editor) do
    word_count = new |> String.split() |> length()
    {:ok, ExEditor.Editor.put_metadata(editor, :word_count, word_count)}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule MyEditor.Plugins.CharCounter do
  @behaviour ExEditor.Plugin

  @impl true
  def on_event(:handle_change, {_old, new}, editor) do
    {:ok, ExEditor.Editor.put_metadata(editor, :char_count, String.length(new))}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end
```

Usage:

```elixir
editor = ExEditor.Editor.new(
  plugins: [MyEditor.Plugins.WordCounter, MyEditor.Plugins.CharCounter]
)

{:ok, editor} = ExEditor.Editor.set_content(editor, "Hello world")

editor.metadata
# %{word_count: 2, char_count: 11}
```

## Custom Events

Trigger custom events with `Editor.notify/3`:

```elixir
defmodule MyEditor.Plugins.AutoSave do
  @behaviour ExEditor.Plugin

  @impl true
  def on_event(:handle_change, {_old, new}, editor) do
    # Store the unsaved content
    {:ok, ExEditor.Editor.put_metadata(editor, :unsaved_changes, true)}
  end

  @impl true
  def on_event(:save, %{path: path}, editor) do
    content = ExEditor.Editor.get_content(editor)
    File.write!(path, content)
    {:ok, ExEditor.Editor.put_metadata(editor, :unsaved_changes, false)}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end
```

Usage:

```elixir
editor = ExEditor.Editor.new(plugins: [MyEditor.Plugins.AutoSave])
{:ok, editor} = ExEditor.Editor.set_content(editor, "Hello world")
# unsaved_changes: true

{:ok, editor} = ExEditor.Editor.notify(editor, :save, %{path: "/tmp/file.txt"})
# unsaved_changes: false
```

## Complete Example: Code Linter

This example uses `:before_change` to reject content with errors and stores
warnings in metadata for the UI to display. Note that `:before_change` runs
the linter and stores warnings regardless of whether the change is accepted --
if the change is rejected, `:handle_change` is never called, so storing
warnings in `:before_change` ensures they are always up to date.

```elixir
defmodule MyEditor.Plugins.Linter do
  @behaviour ExEditor.Plugin

  @impl true
  def on_event(:before_change, {_old, new}, editor) do
    warnings = run_linter(new)
    editor = ExEditor.Editor.put_metadata(editor, :linter_warnings, warnings)
    errors = Enum.filter(warnings, &(&1.severity == :error))

    if Enum.any?(errors) do
      {:error, {:linter_errors, errors}}
    else
      {:ok, editor}
    end
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}

  defp run_linter(content) do
    # Your linting logic here
    []
  end

  def get_warnings(editor) do
    ExEditor.Editor.get_metadata(editor, :linter_warnings) || []
  end
end
```

## Best Practices

1. **Always handle unknown events** - Use a catch-all clause:
   ```elixir
   def on_event(_event, _payload, editor), do: {:ok, editor}
   ```

2. **Use metadata namespacing** - Prefix your keys to avoid collisions:
   ```elixir
   {:ok, Editor.put_metadata(editor, :my_plugin_state, state)}
   ```

3. **Return `{:ok, editor}`** - Even if you don't modify the editor, return the tuple.

4. **Keep plugins focused** - One responsibility per plugin.

5. **Order matters** - List rejection plugins first, then reactive plugins:
   ```elixir
   plugins: [
     ValidationPlugin,    # May reject
     MaxLengthPlugin,     # May reject
     AutoSavePlugin,      # Reactive
     AnalyticsPlugin      # Reactive
   ]
   ```
