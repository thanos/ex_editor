# ExEditor

[![Hex.pm](https://img.shields.io/hexpm/v/ex_editor.svg)](https://hex.pm/packages/ex_editor)
[![Hex.pm](https://img.shields.io/hexpm/dt/ex_editor.svg)](https://hex.pm/packages/ex_editor)
[![Hex.pm](https://img.shields.io/hexpm/l/ex_editor.svg)](https://hex.pm/packages/ex_editor)
[![HexDocs.pm](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_editor)

A headless code editor library for Phoenix LiveView applications with a plugin system for extensibility.

**[Live Demo](https://ex-editor.fly.dev)**

## Features

- **Headless Architecture** - Core editing logic separate from UI concerns
- **LiveView Component** - Ready-to-use `<.live_editor />` component with syntax highlighting
- **Instant Visual Feedback** - Plain text visible immediately while typing, syntax highlighting fades in after 2 seconds of inactivity
- **Native Caret** - Uses browser's native cursor instead of overlay (no disappearing cursor)
- **Line Numbers** - JS-managed line number gutter that updates instantly without server round-trip
- **Double-Buffer Rendering** - Invisible textarea with visible highlighted layer for seamless editing
- **Scroll Synchronization** - Textarea, highlight layer, and gutter stay perfectly aligned during scrolling
- **Line-Based Document Model** - Efficient text manipulation with line operations
- **Plugin System** - Extend functionality through a simple behavior-based plugin API
- **Undo/Redo Support** - Built-in history management with configurable stack size
- **Syntax Highlighting** - Built-in highlighters for Elixir and JSON, easily extensible
- **Comprehensive Testing** - 267 tests, 88.7% coverage with full LiveComponent integration tests

## Installation

### From Hex (when published)

Add `ex_editor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_editor, "~> 0.3.0"}
  ]
end
```

### From GitHub

```elixir
def deps do
  [
    {:ex_editor, github: "thanos/ex_editor"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Quick Start

### Phoenix LiveView Integration

Add the JavaScript hook to your `assets/js/app.js`:

```javascript
import EditorHook from "ex_editor/hooks/editor"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { EditorHook }
})
```

Import the CSS in your `assets/css/app.css`:

```css
@import "ex_editor/css/editor";
```

Use the component in your LiveView:

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

### Component Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:id` | `string` | required | Unique identifier for the editor |
| `:content` | `string` | `""` | Initial content string |
| `:editor` | `Editor.t()` | - | Pre-existing Editor struct |
| `:language` | `atom` | `:elixir` | Syntax highlighting language |
| `:on_change` | `string` | `"change"` | Event name for content changes |
| `:readonly` | `boolean` | `false` | Read-only mode |
| `:line_numbers` | `boolean` | `true` | Show/hide line numbers |
| `:class` | `string` | `""` | Additional CSS classes |
| `:debounce` | `integer` | `300` | Debounce time in milliseconds |

### Supported Languages

Built-in highlighters:

- `:elixir` - Elixir syntax
- `:json` - JSON syntax

## Core Editor API

### Basic Usage

```elixir
# Create a new editor with initial content
editor = ExEditor.Editor.new(content: "Hello, World!\nThis is line 2")

# Get the current content
ExEditor.Editor.get_content(editor)
# => "Hello, World!\nThis is line 2"

# Update content
{:ok, editor} = ExEditor.Editor.set_content(editor, "New content here")

# Work with the underlying document
doc = editor.document
ExEditor.Document.line_count(doc)  # => 1
ExEditor.Document.get_line(doc, 1) # => {:ok, "New content here"}
```

### Document Operations

```elixir
# Create a document from text
doc = ExEditor.Document.from_text("line 1\nline 2\nline 3")

# Insert a new line
{:ok, doc} = ExEditor.Document.insert_line(doc, 2, "inserted line")
# Now: ["line 1", "inserted line", "line 2", "line 3"]

# Replace a line
{:ok, doc} = ExEditor.Document.replace_line(doc, 1, "updated line 1")

# Delete a line
{:ok, doc} = ExEditor.Document.delete_line(doc, 2)

# Get line count
ExEditor.Document.line_count(doc)  # => 3

# Convert back to text
ExEditor.Document.to_text(doc)
# => "updated line 1\nline 2\nline 3"
```

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

## Syntax Highlighting

ExEditor includes optional syntax highlighters:

- `ExEditor.Highlighters.Elixir` - Highlights Elixir code
- `ExEditor.Highlighters.JSON` - Highlights JSON data

```elixir
editor = ExEditor.Editor.new(content: "def hello, do: :world")
editor = ExEditor.Editor.set_highlighter(editor, ExEditor.Highlighters.Elixir)
ExEditor.Editor.get_highlighted_content(editor)
# => "<span class=\"hl-keyword\">def</span> ..."
```

Create custom highlighters by implementing the `ExEditor.Highlighter` behaviour.

## Architecture

### Double-Buffer Rendering

The LiveEditor component uses a "double-buffer" technique:

```
┌─────────────────────────────────────┐
│  Container (relative positioned)    │
│  ┌───────────────────────────────┐  │
│  │ Highlighted Layer (visible)   │  │  Syntax-highlighted code
│  │   - Line numbers              │  │  with fake cursor
│  │   - Fake cursor               │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ Textarea Layer (invisible)    │  │  Captures user input
│  │   - color: transparent        │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

Both layers share identical styling for perfect sync.

### Document Model

The `ExEditor.Document` module provides a line-based text representation:

- Lines are stored as a list of strings
- Line numbers are 1-indexed (line 1 is the first line)
- Supports all line ending formats (\n, \r\n, \r)
- Immutable operations return `{:ok, new_doc}` or `{:error, reason}`

### Editor State

The `ExEditor.Editor` module manages editor state:

- Wraps a `Document` with metadata
- Coordinates plugin execution
- Handles content changes and notifications
- Provides undo/redo with configurable history size
- Provides a simple API for UI integration

## Demo Application

See the included demo application in `demo/` for a complete example.

**[Live Demo](https://ex-editor.fly.dev)**

To run the demo locally:

```bash
cd demo
mix setup
mix phx.server
```

Then visit [http://localhost:4000](http://localhost:4000)

## API Documentation

Full API documentation is available on [HexDocs](https://hexdocs.pm/ex_editor).

Generate docs locally:

```bash
mix docs
```

## Development

### Running Tests

```bash
# Run all tests
mix test

# Run with coverage
mix coveralls

# Generate HTML coverage report
mix coveralls.html
```

### Code Quality

```bash
# Format code
mix format

# Run static analysis
mix credo --strict

# Run security checks
mix sobelow
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests and ensure they pass (`mix test`)
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by the need for headless editor libraries in the Elixir ecosystem
- Built with Phoenix LiveView in mind
- Thanks to the Elixir community for feedback and support