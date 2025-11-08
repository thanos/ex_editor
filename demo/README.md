# ExEditor Demo Application

A full-featured demonstration of the ExEditor library in action with Phoenix LiveView.

## Overview

This demo showcases ExEditor's capabilities with:

- **Real-time editing** - LiveView-powered editor with instant updates
- **VS Code dark theme** - Professional dark color scheme (#1e1e1e background)
- **Side-by-side view** - Editor on left, raw content on right
- **Cursor tracking** - Live cursor position display (Ln/Col)
- **JavaScript hooks** - EditorSync hook for advanced textarea synchronization
- **Clean architecture** - Demonstrates proper integration patterns

## Quick Start

### Prerequisites

- Elixir 1.15 or later
- Erlang/OTP 26 or later
- SQLite3 (for demo database)

### Installation

```bash
# From the demo directory
cd demo

# Install dependencies
mix deps.get

# Create and migrate database
mix ecto.setup

# Install and build assets
mix assets.setup
mix assets.build

# Or run everything at once
mix setup
```

### Running the Demo

```bash
# Start the Phoenix server
mix phx.server
```

Now visit [`http://localhost:4000`](http://localhost:4000) in your browser.

You should see the ExEditor demo with:
- A header showing "ExEditor Demo"
- Cursor position badge (Ln/Col)
- Side-by-side editor and raw content view
- Sample Elixir code loaded in the editor

## Features Demonstrated

### 1. Real-time Content Synchronization

The demo shows how ExEditor integrates with LiveView for real-time updates:

```elixir
def handle_event("update_content", %{"content" => content}, socket) do
  case ExEditor.Editor.set_content(socket.assigns.editor, content) do
    {:ok, updated_editor} ->
      {:noreply, assign(socket, :editor, updated_editor)}
  end
end
```

### 2. JavaScript Hook Integration

The `EditorSync` hook (`assets/js/hooks/editor_sync.js`) demonstrates:
- Content change detection with debouncing
- Cursor position tracking
- Event communication with LiveView

### 3. Custom Styling

Shows how to apply custom themes to ExEditor:
- VS Code dark theme colors
- Custom scrollbars
- Syntax highlighting ready

## Project Structure

```
demo/
├── assets/              # Frontend assets
│   ├── css/
│   │   └── app.css     # Tailwind + custom styles
│   └── js/
│       ├── app.js      # Main JS entry point
│       └── hooks/
│           └── editor_sync.js  # EditorSync hook
├── lib/
│   ├── demo/           # Application code
│   └── demo_web/       # Web interface
│       └── live/
│           └── editor_live.ex  # Main demo LiveView
├── test/               # Tests
└── mix.exs            # Dependencies (includes {:ex_editor, path: ".."})
```

## Development

### Running Tests

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover
```

### Code Quality

```bash
# Format code
mix format

# Check formatting
mix format --check-formatted

# Run linter
mix credo
```

### Asset Development

```bash
# Watch and rebuild assets automatically
mix phx.server

# Or manually rebuild
mix assets.build
```

## Customization

### Changing the Theme

Edit `assets/css/app.css` to customize colors:

```css
@plugin "../vendor/daisyui-theme" {
  name: "dark";
  --color-base-100: oklch(15% 0.01 252);  /* Background */
  --color-base-content: oklch(83% 0.01 252);  /* Text */
  /* ... */
}
```

### Adding Features

The demo is designed to be extended. Try adding:

1. **Syntax highlighting** - Integrate a syntax highlighter
2. **Line numbers** - Display line numbers in the gutter
3. **Search/replace** - Add find and replace functionality
4. **Multiple files** - Support switching between files
5. **Collaborative editing** - Add real-time collaboration

## Troubleshooting

### Port already in use

```bash
# Kill the process using port 4000
lsof -ti:4000 | xargs kill -9
```

### Assets not loading

```bash
# Rebuild assets
mix assets.build
```

### Database issues

```bash
# Reset the database
mix ecto.reset
```

## Learn More

- **ExEditor Library**: See the root README for library documentation
- **Phoenix Framework**: https://www.phoenixframework.org/
- **Phoenix LiveView**: https://hexdocs.pm/phoenix_live_view/
- **Tailwind CSS**: https://tailwindcss.com/

## Contributing

Found a bug or have a feature idea? 

1. Check the main repo issues: https://github.com/thanos/ex_editor/issues
2. Submit a pull request with your improvement
3. Make sure tests pass: `mix test`

## License

MIT License - see the root LICENSE file for details.

