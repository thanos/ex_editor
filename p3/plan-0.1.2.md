# Plugin API Refactor Plan (v0.1.2)

**Status**: Planned  
**Version**: 0.1.1 → 0.2.0  
**Type**: Breaking Change

## Overview

Refactor the Plugin API to create a consistent, powerful plugin system with:
- Unified `on_event/3` callback
- `:before_change` event for validation/rejection
- `:handle_change` event for reacting to changes
- Metadata field for plugin state storage
- Public `notify/3` API for custom events

## Problem Analysis

### Current Issues

1. **`lib/ex_editor/plugin.ex`** (lines 39-52):
   - `render/2` returns `Phoenix.LiveView.Rendered.t()` - creates Phoenix dependency
   - `handle_change/2` signature doesn't match Editor usage
   - No flexibility for custom events

2. **`lib/ex_editor/editor.ex`** (lines 183-189):
   - `notify_plugins/2` uses `Enum.each` - discards plugin return values
   - Plugins cannot modify editor state
   - No middleware chain support

3. **`README.md`** (lines 100-114):
   - Shows `on_event/3` pattern but Plugin behaviour defines different callbacks
   - Inconsistent documentation

---

## Implementation Details

### File 1: `lib/ex_editor/editor.ex`

#### Changes to struct definition (line 50-57)

```elixir
defstruct [:document, :plugins, :highlighter, :metadata, :options]

@type t :: %__MODULE__{
        document: Document.t(),
        plugins: list(module()),
        highlighter: module() | nil,
        metadata: map(),
        options: keyword()
      }
```

#### Changes to `new/1` (line 81-94)

```elixir
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
```

#### New function `put_metadata/3` (insert after `set_highlighter/2`)

```elixir
@doc """
Stores metadata in the editor for plugin use.

## Example

    editor = Editor.put_metadata(editor, :my_plugin, %{state: :active})
"""
@spec put_metadata(t(), atom(), term()) :: t()
def put_metadata(%__MODULE__{metadata: metadata} = editor, key, value) do
  %{editor | metadata: Map.put(metadata, key, value)}
end
```

#### Changes to `set_content/2` (lines 127-140)

```elixir
def set_content(%__MODULE__{} = editor, content) when is_binary(content) do
  old_content = get_content(editor)
  
  with {:ok, editor} <- notify_plugins(editor, :before_change, {old_content, content}),
       new_document = Document.from_text(content),
       editor = %{editor | document: new_document},
       {:ok, editor} <- notify_plugins(editor, :handle_change, {old_content, content}) do
    {:ok, editor}
  end
end
```

#### New public function `notify/3` (insert after `set_content/2`)

```elixir
@doc """
Notifies plugins of a custom event.

## Example

    {:ok, editor} = Editor.notify(editor, :save, %{path: "file.ex"})
"""
@spec notify(t(), atom(), term()) :: {:ok, t()} | {:error, term()}
def notify(%__MODULE__{} = editor, event, payload) do
  notify_plugins(editor, event, payload)
end
```

#### Changes to `notify_plugins/2` (lines 183-189)

```elixir
defp notify_plugins(editor, event, payload) do
  Enum.reduce_while(editor.plugins, {:ok, editor}, fn plugin, {:ok, ed} ->
    if function_exported?(plugin, :on_event, 3) do
      case plugin.on_event(event, payload, ed) do
        {:ok, updated_editor} -> {:cont, {:ok, updated_editor}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    else
      {:cont, {:ok, ed}}
    end
  end)
end
```

---

### File 2: `lib/ex_editor/plugin.ex`

#### Complete rewrite

```elixir
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
          # Store state in metadata
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
```

---

### File 3: `README.md`

#### Update Plugin section (replace lines 96-128)

```markdown
### Using Plugins

Create a plugin by implementing the `ExEditor.Plugin` behaviour:

```elixir
defmodule MyApp.EditorPlugins.MaxLength do
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

Use it with your editor:

```elixir
editor = ExEditor.Editor.new(
  content: "Initial content",
  plugins: [MyApp.EditorPlugins.MaxLength]
)

# This will succeed
{:ok, editor} = ExEditor.Editor.set_content(editor, "Short text")

# This will fail if content exceeds max length
{:error, :content_too_long} = ExEditor.Editor.set_content(editor, long_content)
```

### Plugin Events

| Event | Payload | Purpose |
|-------|---------|---------|
| `:before_change` | `{old_content, new_content}` | Validate/reject changes |
| `:handle_change` | `{old_content, new_content}` | React to changes |
| Custom | Any | Application-defined |

### Plugin Metadata

Plugins can store state in editor metadata:

```elixir
def on_event(:handle_change, {_old, new}, editor) do
  {:ok, Editor.put_metadata(editor, :my_plugin, %{last_saved: new})}
end
```
```

---

### File 4: `test/ex_editor/editor_test.exs`

#### Add new tests (append to file)

```elixir
defmodule ExEditor.EditorPluginTest do
  use ExUnit.Case, async: true
  
  alias ExEditor.Editor
  
  describe "plugin system" do
    test "receives handle_change event on content change" do
      defmodule SpyPlugin do
        @behaviour ExEditor.Plugin
        Agent.start_link(fn -> [] end, name: __MODULE__)
        
        @impl true
        def on_event(:handle_change, payload, editor) do
          Agent.update(__MODULE__, &[payload | &1])
          {:ok, editor}
        end
        
        @impl true
        def on_event(_, _, editor), do: {:ok, editor}
        
        def get_events do
          Agent.get(__MODULE__, & &1)
        end
      end
      
      {:ok, editor} = Editor.new(plugins: [SpyPlugin])
      {:ok, _editor} = Editor.set_content(editor, "new content")
      
      assert [{"", "new content"} | _] = SpyPlugin.get_events()
    after
      Agent.stop(SpyPlugin)
    end
    
    test "before_change can reject changes" do
      defmodule RejectPlugin do
        @behaviour ExEditor.Plugin
        
        @impl true
        def on_event(:before_change, {_old, new}, _editor) do
          if String.contains?(new, "forbidden") do
            {:error, :forbidden_word}
          else
            {:ok, _editor}
          end
        end
        
        @impl true
        def on_event(_, _, editor), do: {:ok, editor}
      end
      
      {:ok, editor} = Editor.new(plugins: [RejectPlugin])
      
      assert {:error, :forbidden_word} = Editor.set_content(editor, "forbidden content")
      assert {:ok, _} = Editor.set_content(editor, "allowed content")
    end
    
    test "plugins can modify editor via metadata" do
      defmodule MetaPlugin do
        @behaviour ExEditor.Plugin
        
        @impl true
        def on_event(:handle_change, {_old, new}, editor) do
          {:ok, Editor.put_metadata(editor, :change_count, String.length(new))}
        end
        
        @impl true
        def on_event(_, _, editor), do: {:ok, editor}
      end
      
      {:ok, editor} = Editor.new(plugins: [MetaPlugin])
      {:ok, editor} = Editor.set_content(editor, "hello")
      
      assert editor.metadata[:change_count] == 5
    end
    
    test "multiple plugins form middleware chain" do
      defmodule CounterPlugin do
        @behaviour ExEditor.Plugin
        
        @impl true
        def on_event(:handle_change, _, editor) do
          count = Map.get(editor.metadata, :count, 0)
          {:ok, Editor.put_metadata(editor, :count, count + 1)}
        end
        
        @impl true
        def on_event(_, _, editor), do: {:ok, editor}
      end
      
      {:ok, editor} = Editor.new(plugins: [CounterPlugin, CounterPlugin])
      {:ok, editor} = Editor.set_content(editor, "test")
      
      assert editor.metadata[:count] == 2
    end
    
    test "custom events via notify/3" do
      defmodule CustomPlugin do
        @behaviour ExEditor.Plugin
        
        @impl true
        def on_event(:custom, payload, editor) do
          {:ok, Editor.put_metadata(editor, :custom, payload)}
        end
        
        @impl true
        def on_event(_, _, editor), do: {:ok, editor}
      end
      
      {:ok, editor} = Editor.new(plugins: [CustomPlugin])
      {:ok, editor} = Editor.notify(editor, :custom, %{data: "test"})
      
      assert editor.metadata[:custom] == %{data: "test"}
    end
  end
end
```

---

## Execution Order

1. [ ] Update `lib/ex_editor/plugin.ex` - New behaviour definition
2. [ ] Update `lib/ex_editor/editor.ex` - Struct, callbacks, notify_plugins, new functions
3. [ ] Update `README.md` - Fix documentation
4. [ ] Add tests to `test/ex_editor/editor_test.exs` - Verify everything works
5. [ ] Run tests - `mix test`
6. [ ] Update version - Bump to `0.2.0` in `mix.exs`

---

## Summary

| Aspect | Value |
|--------|-------|
| Files changed | 4 |
| New functions | 2 (`notify/3`, `put_metadata/3`) |
| New struct fields | 1 (`metadata: map()`) |
| New events | 1 (`:before_change`) |
| Breaking changes | Yes (plugin callback signature) |
| Version bump | 0.1.1 → 0.2.0 |

---

## Decisions Made

- ✅ Add `:before_change` event for validation/rejection
- ✅ Add `metadata` field to Editor struct for plugin state