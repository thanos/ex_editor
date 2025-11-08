# ExEditor

[![Hex.pm](https://img.shields.io/hexpm/v/ex_editor.svg)](https://hex.pm/packages/ex_editor)
[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/ex_editor)
[![CI](https://github.com/thanos/ex_editor/workflows/CI/badge.svg)](https://github.com/thanos/ex_editor/actions)
[![Coverage](https://coveralls.io/repos/github/thanos/ex_editor/badge.svg?branch=main)](https://coveralls.io/github/thanos/ex_editor?branch=main)

A headless, extensible code editor library for Phoenix LiveView applications.

ExEditor provides a clean separation between editor state management and UI rendering, making it easy to build custom code editors with your own styling and behavior while leveraging a robust document model and plugin system.

## Features

- 🎯 **Headless Architecture** - Pure Elixir document management with no UI dependencies
- 🔌 **Plugin System** - Extend functionality with custom plugins
- 📝 **Document Model** - Robust line-based document representation
- 🔄 **Real-time Ready** - Built for Phoenix LiveView integration
- 🧪 **Well Tested** - 95%+ test coverage
- 📚 **Documented** - Comprehensive docs and examples

## Installation

Add `ex_editor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_editor, "~> 0.1.0"}
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
# Create a new editor
editor = ExEditor.Editor.new()

# Set initial content
{:ok, editor} = ExEditor.Editor.set_content(editor, """
defmodule MyModule do
  def hello(name) do
    "Hello, #{name}!"
  end
end
""")

# Get the content back
content = ExEditor.Editor.get_content(editor)
```

### Phoenix LiveView Integration

Here's a minimal LiveView example:

```elixir
defmodule MyAppWeb.EditorLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    editor = ExEditor.Editor.new(content: "# Start typing...")
    
    {:ok,
     socket
     |> assign(:editor, editor)}
  end

  @impl true
  def handle_event("update_content", %{"content" => content}, socket) do
    case ExEditor.Editor.set_content(socket.assigns.editor, content) do
      {:ok, updated_editor} ->
        {:noreply, assign(socket, :editor, updated_editor)}
      
      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Code Editor</h1>
      <form phx-change="update_content">
        <textarea
          name="content"
          class="font-mono w-full h-96 p-4 border rounded"
        ><%= ExEditor.Editor.get_content(@editor) %></textarea>
      </form>
    </div>
    """
  end
end
```

## Document Model

ExEditor uses a line-based document model that provides efficient operations on text:

```elixir
# Create document from text
doc = ExEditor.Document.from_text("line 1\nline 2\nline 3")

# Get line count
ExEditor.Document.line_count(doc)  # => 3

# Get specific line (1-indexed)
{:ok, line} = ExEditor.Document.get_line(doc, 2)  # => {:ok, "line 2"}

# Insert a new line
{:ok, doc} = ExEditor.Document.insert_line(doc, 2, "new line")
# Result: "line 1\nnew line\nline 2\nline 3"

# Replace a line
{:ok, doc} = ExEditor.Document.replace_line(doc, 1, "updated line 1")

# Delete a line
{:ok, doc} = ExEditor.Document.delete_line(doc, 3)

# Convert back to text
text = ExEditor.Document.to_text(doc)
```

### Line Numbering

ExEditor uses **1-based indexing** for lines (line 1 is the first line), which matches most code editors and makes integration more intuitive.

### Line Endings

The document model automatically handles different line ending formats (`\n`, `\r\n`, `\r`) and normalizes them to `\n` internally.

## Plugin System

ExEditor provides a flexible plugin system for extending functionality:

```elixir
defmodule MyPlugin do
  @behaviour ExEditor.Plugin

  @impl true
  def on_event(:handle_change, _payload, editor) do
    # Perform custom logic when content changes
    IO.puts("Content was updated!")
    {:ok, editor}
  end
end

# Use the plugin
editor = ExEditor.Editor.new(plugins: [MyPlugin])
```

### Available Events

- `:handle_change` - Fired when document content changes

Plugins can transform the editor state and are called in order, allowing you to build powerful editing features like:

- Syntax validation
- Auto-formatting
- Collaborative editing
- Custom linting
- And more!

## Advanced Features

### Custom Editor Options

```elixir
editor = ExEditor.Editor.new(
  content: "initial content",
  plugins: [SyntaxHighlight, AutoFormat],
  tab_size: 2,
  theme: :dark
)
```

### Error Handling

All operations return `{:ok, result}` or `{:error, reason}` tuples:

```elixir
case ExEditor.Document.get_line(doc, 999) do
  {:ok, line} ->
    IO.puts("Line: #{line}")
  
  {:error, :invalid_line} ->
    IO.puts("Line doesn't exist")
end
```

## Demo Application

A full-featured demo Phoenix application is included in the `demo/` directory, showcasing:

- Real-time editor with LiveView
- VS Code-inspired dark theme
- Side-by-side editor and raw content view
- Cursor position tracking
- JavaScript hooks for advanced features

To run the demo:

```bash
cd demo
mix setup
mix phx.server
```

Visit `http://localhost:4000` to see the editor in action!

## Architecture

ExEditor follows a clean architecture:

```
ex_editor/
├── lib/
│   └── ex_editor/
│       ├── document.ex      # Core document model
│       ├── editor.ex        # Editor state manager
│       └── plugin.ex        # Plugin behavior
└── demo/                    # Phoenix demo app
    └── lib/
        └── demo_web/
            └── live/
                └── editor_live.ex
```

The library is completely headless - all UI concerns are handled by your application, giving you complete control over styling and behavior.

## Testing

ExEditor has comprehensive test coverage:

```bash
# Run tests
mix test

# Run with coverage
mix coveralls

# Generate HTML coverage report
mix coveralls.html
```

## Documentation

Full documentation is available on [HexDocs](https://hexdocs.pm/ex_editor) or can be generated locally:

```bash
mix docs
open doc/index.html
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass and coverage remains high
5. Submit a pull request

### Development Setup

```bash
# Clone the repo
git clone https://github.com/thanos/ex_editor.git
cd ex_editor

# Install dependencies
mix deps.get

# Run tests
mix test

# Run code quality checks
mix credo --strict
mix format --check-formatted
```

## Roadmap

- [ ] Syntax highlighting integration
- [ ] Undo/redo support
- [ ] Multi-cursor editing
- [ ] Collaborative editing via CRDT
- [ ] Language server protocol (LSP) integration
- [ ] Performance optimizations for large files

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Created and maintained by [Thanos](https://github.com/thanos).

Inspired by modern code editors like VS Code, Vim, and Emacs, but built for the Elixir ecosystem.

## Links

- [Hex Package](https://hex.pm/packages/ex_editor)
- [Documentation](https://hexdocs.pm/ex_editor)
- [GitHub](https://github.com/thanos/ex_editor)
- [Issue Tracker](https://github.com/thanos/ex_editor/issues)
- [Changelog](CHANGELOG.md)

