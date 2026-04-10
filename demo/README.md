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

### Demo Pages

**Main Editor** - [http://localhost:4000](http://localhost:4000)
- Interactive editor with side-by-side preview
- Sample Elixir code with syntax highlighting
- Real-time content synchronization

**Backpex Admin** - [http://localhost:4000/admin/code_snippets](http://localhost:4000/admin/code_snippets)
- Full CRUD interface for code snippets
- CodeField: Elixir syntax-highlighted code editing
- JsonField: JSON configuration editing with pretty-print
- Custom fields demonstrate Backpex integration patterns

## Features Demonstrated

### 1. Real-time Content Synchronization with LiveView

The demo shows how ExEditor integrates with Phoenix LiveView for real-time updates:

```elixir
def handle_info({:code_changed, %{content: new_code}}, socket) do
  {:noreply, assign(socket, :code, new_code)}
end
```

### 2. Backpex Admin Panel Integration

Custom Backpex field implementations for structured data editing:

- **CodeField** - Syntax-highlighted Elixir code editing with line numbers
- **JsonField** - JSON configuration editing with JSON syntax highlighting

```elixir
defmodule DemoWeb.Admin.Fields.CodeField do
  use Backpex.Field, config_schema: @config_schema

  def render_form(assigns) do
    # Uses ExEditorWeb.LiveEditor with Elixir highlighting
    # Syncs with form via EditorFormSync hook
  end
end
```

### 3. JavaScript Hook Integration

Two specialized hooks handle textarea synchronization:

- **EditorHook** (`assets/js/hooks/editor.js`) - Core editor functionality
  - Scroll synchronization between textarea and highlight layer
  - Incremental diff computation (50ms debounce)
  - Line number updating

- **EditorFormSync** (`assets/js/hooks/editor_form_sync.js`) - Form integration
  - Syncs editor content to hidden form inputs
  - Triggers form validation on changes

### 4. Professional Styling & UX

- VS Code dark theme colors with customizable CSS
- Monospace font rendering for consistent character widths
- Smooth scroll synchronization
- High-performance incremental diff updates
- Native browser caret for accurate cursor positioning

## Project Structure

```
demo/
├── assets/              # Frontend assets
│   ├── css/
│   │   └── app.css     # Tailwind + custom styles
│   └── js/
│       ├── app.js      # Main JS entry point
│       └── hooks/
│           ├── editor.js              # Core editor hook (scroll, diffs, line numbers)
│           └── editor_form_sync.js    # Form synchronization hook
├── lib/
│   ├── demo/           # Application code
│   │   └── cms/
│   │       └── code_snippet.ex  # Ecto schema for code snippets
│   └── demo_web/       # Web interface
│       ├── live/
│       │   ├── editor_live.ex         # Main editor demo
│       │   └── admin/
│       │       ├── code_snippet_live.ex    # Backpex resource
│       │       └── fields/
│       │           ├── code_field.ex       # Custom field for Elixir code
│       │           └── json_field.ex       # Custom field for JSON
│       └── endpoint.ex  # Phoenix endpoint
├── priv/
│   └── repo/
│       ├── migrations/
│       │   └── *_create_code_snippets.exs
│       └── seeds.exs    # Sample code snippets
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

## Backpex Admin Integration

This demo showcases how to integrate ExEditor into Backpex admin panels with custom field types.

### Custom Fields Implementation

**CodeField** - For syntax-highlighted code editing:

```elixir
# lib/demo_web/live/admin/fields/code_field.ex
defmodule DemoWeb.Admin.Fields.CodeField do
  use Backpex.Field, config_schema: @config_schema

  @impl Backpex.Field
  def render_form(assigns) do
    ~H"""
    <div class="mb-2 h-96 border border-gray-300 rounded-lg overflow-hidden">
      <.live_component
        module={ExEditorWeb.LiveEditor}
        id={"editor_#{@name}"}
        content={@content}
        language={:elixir}
        on_change="code_changed"
        debounce={100}
      />
    </div>

    <input
      type="hidden"
      name={@form[@name].name}
      value={@content}
      phx-hook="EditorFormSync"
      data-field-id={@form[@name].id}
    />
    """
  end
end
```

**JsonField** - For JSON configuration editing:

```elixir
# lib/demo_web/live/admin/fields/json_field.ex
defmodule DemoWeb.Admin.Fields.JsonField do
  use Backpex.Field, config_schema: @config_schema

  @impl Backpex.Field
  def render_form(assigns) do
    ~H"""
    <div class="mb-2 h-96 border border-gray-300 rounded-lg overflow-hidden">
      <.live_component
        module={ExEditorWeb.LiveEditor}
        id={"editor_#{@name}"}
        content={@content}
        language={:json}
        on_change="code_changed"
        debounce={100}
      />
    </div>

    <input
      type="hidden"
      name={@form[@name].name}
      value={@content}
      phx-hook="EditorFormSync"
      data-field-id={@form[@name].id}
    />
    """
  end
end
```

### Usage in Backpex Resources

```elixir
defmodule DemoWeb.Admin.CodeSnippetLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: CodeSnippet,
      repo: Demo.Repo,
      update_changeset: &CodeSnippet.changeset/3,
      create_changeset: &CodeSnippet.changeset/3
    ]

  @impl Backpex.LiveResource
  def fields do
    [
      name: %{module: Backpex.Fields.Text, label: "Name"},
      code: %{module: DemoWeb.Admin.Fields.CodeField, label: "Code", rows: 10},
      args: %{module: DemoWeb.Admin.Fields.JsonField, label: "Args (JSON)", rows: 5}
    ]
  end
end
```

### Form Synchronization Hook

The `EditorFormSync` hook syncs textarea changes to the hidden form input:

```javascript
// assets/js/hooks/editor_form_sync.js
export default {
  mounted() {
    const editor = this.el.querySelector('[phx-hook="EditorHook"]');
    if (!editor) return;

    const textarea = editor.querySelector('.ex-editor-textarea');
    const syncInput = document.querySelector(`[data-field-id="${this.el.dataset.fieldId}"]`);

    textarea.addEventListener('input', () => {
      syncInput.value = textarea.value;
      syncInput.dispatchEvent(new Event('change'));
    });
  }
};
```

## Customization

### Changing the Theme

Edit `assets/css/app.css` to customize colors:

```css
.ex-editor-container {
  background: #1e1e1e;
  color: #d4d4d4;
}
```

### Extending Field Types

Create custom Backpex fields for other languages:

```elixir
defmodule DemoWeb.Admin.Fields.RustField do
  use Backpex.Field, config_schema: @config_schema

  def render_form(assigns) do
    ~H"""
    <.live_component
      module={ExEditorWeb.LiveEditor}
      id={"editor_#{@name}"}
      content={@content}
      language={:rust}
      on_change="code_changed"
    />
    """
  end
end
```

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

