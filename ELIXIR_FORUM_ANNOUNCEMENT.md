# ExEditor v0.3.0 Release: Production-Ready Code Editor for Phoenix LiveView

Hello Elixir community!

I'm excited to announce **ExEditor v0.3.0**, a production-ready code editor library for Phoenix LiveView applications. This release brings significant performance improvements, Backpex admin integration, and comprehensive documentation.

## What is ExEditor?

ExEditor is a headless code editor library that provides:
- A ready-to-use LiveEditor component with syntax highlighting
- Double-buffer rendering (invisible textarea + visible highlighted layer)
- Native browser caret and perfect scroll synchronization
- A flexible plugin system for extensibility
- Built-in syntax highlighters for Elixir and JSON

Think of it as a building block for applications that need code editing capabilities - from admin panels to full IDEs.

## Highlights of v0.3.0

### Performance: Incremental Diff Synchronization

The biggest improvement in this release is replacing full-content updates with incremental diffs:

**Before**: Every keystroke sent the entire editor content (typically ~120 bytes, 2000ms latency)

**After**: Only changed regions are sent using `{from, to, text}` operations (~20 bytes, 50ms latency)

This results in:
- ✅ **4-6x smaller payloads** - less bandwidth
- ✅ **Always-visible highlighting** - no more 2-second gap where text appears unhighlighted
- ✅ **Faster server processing** - smaller deltas use fewer CPU cycles
- ✅ **Better UX** - users see previous syntax highlighting while new updates load

### Backpex Admin Integration

ExEditor now integrates seamlessly with Backpex, allowing you to embed a full-featured code editor directly in your admin panels:

```elixir
# Define a code editor field for your Backpex resource
def fields do
  [
    name: %{module: Backpex.Fields.Text, label: "Name"},
    code: %{
      module: MyAppWeb.Admin.Fields.CodeEditor,
      label: "Code"
    }
  ]
end
```

Features:
- Syntax-highlighted editing in forms
- Readonly display with line numbers on show pages
- Automatic form synchronization via EditorFormSync hook
- Full documentation with step-by-step implementation guide

### Responsive Interactions

- **Native Caret**: Uses browser's native cursor instead of JavaScript overlay (no disappearing cursor bugs)
- **Instant Line Numbers**: Line count updates immediately via JavaScript (no server round-trip needed)
- **Perfect Scroll Sync**: Textarea, highlight layer, and gutter stay aligned perfectly during scrolling

### Quality & Testing

- **285 tests** (12 doctests + 273 unit tests) with **88.7%+ coverage**
- Full LiveComponent integration tests using `phoenix_test`
- Comprehensive documentation including a detailed Backpex integration guide
- Working demo application showcasing all features

## Live Demo

Check out the live demo at **https://ex-editor.fly.dev** to see ExEditor in action, including the Backpex admin integration with code snippet management.

## Quick Start

### Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:ex_editor, "~> 0.3.0"}
  ]
end
```

### Basic Usage

```elixir
defmodule MyAppWeb.EditorLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :code, "# Hello, World!")}
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
| `:id` | `string` | required | Unique editor identifier |
| `:content` | `string` | `""` | Initial code content |
| `:language` | `atom` | `:elixir` | Syntax highlighting language |
| `:on_change` | `string` | `"change"` | Event name for changes |
| `:readonly` | `boolean` | `false` | Read-only mode |
| `:line_numbers` | `boolean` | `true` | Show/hide line numbers |
| `:debounce` | `integer` | `50` | Debounce time in milliseconds |

## Architecture

The editor uses a "double-buffer" approach:

```
┌─────────────────────────────────────┐
│  Container                          │
│  ┌───────────────────────────────┐  │
│  │ Highlighted Layer (visible)   │  │  Displays syntax-highlighted code
│  │ - Line numbers                │  │  - Updates on content changes
│  │ - Code with colors            │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ Textarea Layer (transparent)  │  │  Captures user input
│  │ - Captures typing             │  │  - Sends diffs to server
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

Both layers are perfectly synchronized in size and position, and the editor computes minimal diffs to send to the server.

## Documentation

- **GitHub Repository**: https://github.com/thanos/ex_editor
- **Hex Package**: https://hex.pm/packages/ex_editor
- **API Documentation**: https://hexdocs.pm/ex_editor
- **Backpex Integration Guide**: https://github.com/thanos/ex_editor/blob/main/guides/BACKPEX_INTEGRATION.md
- **Live Demo**: https://ex-editor.fly.dev

## What's Next?

Future versions may include:
- Code folding
- Bracket auto-closing
- Search/find functionality
- Multiple cursor support
- Virtualized rendering for 10k+ line files

## Backwards Compatibility

v0.3.0 is fully backward compatible with v0.2.0. No breaking changes to the public API.

## Questions & Discussion

I'd love to hear your feedback and use cases! Feel free to ask questions in this thread or open issues on GitHub.

Special thanks to the Elixir and Phoenix communities for creating such an amazing ecosystem. The productivity and developer experience in this stack continue to impress me.

Happy coding! 🎉

---

**Links**:
- 🌐 **Live Demo**: https://ex-editor.fly.dev
- 📦 **Hex Package**: https://hex.pm/packages/ex_editor
- 📚 **Documentation**: https://hexdocs.pm/ex_editor
- 💻 **GitHub**: https://github.com/thanos/ex_editor
- 🎓 **Backpex Guide**: https://github.com/thanos/ex_editor/blob/main/guides/BACKPEX_INTEGRATION.md
