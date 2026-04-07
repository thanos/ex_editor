# Phoenix LiveView Integration

This guide explains how to integrate ExEditor into your Phoenix LiveView application.

## Installation

Add `ex_editor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_editor, "~> 0.3.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Setup

### 1. Import the JavaScript Hook

In your `assets/js/app.js`, import the Editor hook:

```javascript
import EditorHook from "ex_editor/hooks/editor"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { EditorHook }
})
```

### 2. Import the CSS

In your `assets/css/app.css`:

```css
@import "ex_editor/css/editor";
```

Or with Tailwind CSS:

```css
@import "tailwindcss";

/* ExEditor styles */
.ex-editor-container {
  /* Your customizations */
}
```

## Basic Usage

### Simple Editor

```elixir
defmodule MyAppWeb.EditorLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :code, "def hello, do: :world")}
  end

  def render(assigns) do
    ~H"""
    <ExEditorWeb.LiveEditor.live_editor
      id="code-editor"
      content={@code}
      language={:elixir}
      on_change="code_changed"
    />
    """
  end

  def handle_event("code_changed", %{"content" => new_code}, socket) do
    {:noreply, assign(socket, :code, new_code)}
  end
end
```

### With Editor Struct

For more control, use an `ExEditor.Editor` struct:

```elixir
defmodule MyAppWeb.EditorLive do
  use MyAppWeb, :live_view

  alias ExEditor.Editor

  def mount(_params, _session, socket) do
    editor =
      Editor.new(content: "def hello, do: :world")
      |> Editor.set_highlighter(ExEditor.Highlighters.Elixir)

    {:ok, assign(socket, :editor, editor)}
  end

  def render(assigns) do
    ~H"""
    <ExEditorWeb.LiveEditor.live_editor
      id="code-editor"
      editor={@editor}
      on_change="editor_changed"
    />
    """
  end

  def handle_event("editor_changed", %{"content" => new_code, "editor": editor}, socket) do
    {:noreply, assign(socket, :editor, editor)}
  end
end
```

## Component Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:id` | `string` | required | Unique identifier for the editor |
| `:content` | `string` | `""` | Initial content (mutually exclusive with `:editor`) |
| `:editor` | `Editor.t()` | - | An `ExEditor.Editor` struct |
| `:language` | `atom` | `:elixir` | Language for syntax highlighting (`:elixir`, `:json`) |
| `:on_change` | `string` | `"change"` | Event name pushed when content changes |
| `:readonly` | `boolean` | `false` | Whether the editor is read-only |
| `:line_numbers` | `boolean` | `true` | Whether to show line numbers |
| `:class` | `string` | `""` | Additional CSS classes for the container |
| `:debounce` | `integer` | `300` | Debounce time in milliseconds |
| `:theme` | `string` | `"dark"` | Editor theme (`"dark"` or `"light"`) |

## Supported Languages

Built-in highlighters:

- `:elixir` - Elixir syntax highlighting
- `:json` - JSON syntax highlighting

### Custom Highlighters

You can create custom highlighters by implementing the `ExEditor.Highlighter` behaviour:

```elixir
defmodule MyApp.Highlighters.MyLanguage do
  @behaviour ExEditor.Highlighter

  @impl true
  def name, do: "MyLanguage"

  @impl true
  def highlight(text) do
    # Transform text into highlighted HTML
    # Use CSS classes: hl-keyword, hl-string, hl-number, etc.
  end
end
```

Use it with:

```elixir
editor = Editor.new(content: "...")
editor = Editor.set_highlighter(editor, MyApp.Highlighters.MyLanguage)
```

## Styling

### Default CSS Classes

ExEditor uses these CSS classes:

- `.ex-editor-container` - Main container
- `.ex-editor-wrapper` - Inner wrapper
- `.ex-editor-line-numbers` - Line numbers gutter
- `.ex-editor-highlight` - Syntax-highlighted layer
- `.ex-editor-textarea` - Invisible textarea for input
- `.ex-editor-line` - Individual line wrapper
- `.ex-editor-cursor` - Fake cursor element

### Syntax Highlighting Classes

These classes are used by highlighters:

- `.hl-keyword` - Language keywords
- `.hl-string` - String literals
- `.hl-number` - Numeric literals
- `.hl-boolean` - Boolean values
- `.hl-null` - Null/nil values
- `.hl-key` - Object/map keys
- `.hl-punctuation` - Brackets, braces, commas
- `.hl-comment` - Comments
- `.hl-operator` - Operators
- `.hl-function` - Function names
- `.hl-variable` - Variables

## Plugin System

ExEditor supports plugins for extending functionality:

```elixir
defmodule MyApp.Plugins.MaxLength do
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

# Use with editor
editor = Editor.new(plugins: [MyApp.Plugins.MaxLength])
```

## Troubleshooting

### Cursor Position Incorrect

Ensure you're using a monospace font. ExEditor relies on consistent character widths for cursor positioning.

### Scroll Sync Issues

Both layers should have identical styling (font, padding, line-height). Check that no CSS is overriding the editor styles.

### Highlighter Not Working

Verify the highlighter is set correctly:

```elixir
editor = Editor.set_highlighter(editor, ExEditor.Highlighters.Elixir)
```

Check that CSS classes are included in your stylesheet.

## Demo Application

See the `demo/` directory in the ExEditor repository for a complete working example.

To run the demo locally:

```bash
cd demo
mix setup
mix phx.server
```

Then visit [http://localhost:4000](http://localhost:4000).