# ExEditor


[![Hex.pm](https://img.shields.io/hexpm/v/ex_editor.svg)](https://hex.pm/packages/ex_editor)
[![Hex.pm](https://img.shields.io/hexpm/dt/ex_editor.svg)](https://hex.pm/packages/ex_editor)
[![Hex.pm](https://img.shields.io/hexpm/l/ex_editor.svg)](https://hex.pm/packages/ex_editor)
[![HexDocs.pm](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_editor)


A headless code editor library for Phoenix LiveView applications with a plugin system for extensibility. This code is pre-production.

## Features

- **Headless Architecture** - Core editing logic separate from UI concerns
- **Line-Based Document Model** - Efficient text manipulation with line operations
- **Plugin System** - Extend functionality through a simple behavior-based plugin API
- **LiveView Ready** - Designed for real-time collaborative editing
- **Battle-Tested** - 95%+ test coverage with comprehensive unit tests
- **Zero Runtime Dependencies** - Pure Elixir library with no external runtime deps

## Installation

### From Hex (when published)

Add `ex_editor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_editor, "~> 0.2.0"}
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

### Plugin Metadata

Plugins can store state in editor metadata:

```elixir
def on_event(:handle_change, {_old, new}, editor) do
  {:ok, ExEditor.Editor.put_metadata(editor, :my_plugin, %{last_saved: new})}
end
```

## Phoenix LiveView Integration

See the included demo application in `demo/` for a complete example of integrating ExEditor with Phoenix LiveView.

The demo showcases:
- Real-time content synchronization
- Cursor position tracking
- VS Code-inspired dark theme
- JavaScript hooks for advanced features

To run the demo:

```bash
cd demo
mix setup
mix phx.server
```

Then visit [http://localhost:4000](http://localhost:4000)

## Architecture

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
- Provides a simple API for UI integration

### Plugin System

Plugins implement the `ExEditor.Plugin` behaviour:

```elixir
@callback on_event(event :: atom(), payload :: term(), editor :: Editor.t()) ::
  {:ok, Editor.t()} | {:error, term()}
```

Plugins receive events for:
- `:before_change` - Before content changes (can reject)
- `:handle_change` - After content has changed
- Custom events via `Editor.notify/3`

## API Documentation

Full API documentation is available on [HexDocs](https://hexdocs.pm/ex_editor) (when published).

You can also generate docs locally:

```bash
mix docs
```

Then open `doc/index.html` in your browser.

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
