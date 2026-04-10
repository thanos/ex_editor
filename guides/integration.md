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

### Simple Editor with Content

```elixir
defmodule MyAppWeb.EditorLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :code, "def hello, do: :world")}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={ExEditorWeb.LiveEditor}
      id="code-editor"
      content={@code}
      language={:elixir}
      on_change="code_changed"
      debounce={50}
    />
    """
  end

  def handle_info({:code_changed, %{content: new_code}}, socket) do
    {:noreply, assign(socket, :code, new_code)}
  end
end
```

### Full-Featured Editor with Editor Struct

For more control over highlighting and plugins:

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
    <.live_component
      module={ExEditorWeb.LiveEditor}
      id="code-editor"
      content={Editor.get_content(@editor)}
      language={:elixir}
      on_change="code_changed"
      readonly={false}
      line_numbers={true}
    />
    """
  end

  def handle_info({:code_changed, %{content: new_code}}, socket) do
    editor = socket.assigns.editor
    case Editor.set_content(editor, new_code) do
      {:ok, updated_editor} ->
        {:noreply, assign(socket, :editor, updated_editor)}
      {:error, _reason} ->
        {:noreply, socket}
    end
  end
end
```

## Component Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:id` | `string` | required | Unique identifier for the editor |
| `:content` | `string` | `""` | Initial content |
| `:language` | `atom` | `:elixir` | Language for syntax highlighting (`:elixir`, `:json`) |
| `:on_change` | `string` | `"code_changed"` | Event name sent to parent LiveView |
| `:readonly` | `boolean` | `false` | Whether the editor is read-only |
| `:line_numbers` | `boolean` | `true` | Whether to show line numbers |
| `:class` | `string` | `""` | Additional CSS classes for the container |
| `:debounce` | `integer` | `50` | Debounce time in milliseconds for incremental diffs |

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

## Backpex Admin Panel Integration

ExEditor integrates seamlessly with Backpex for building custom field types in admin panels.

### Creating a Custom Backpex Field

```elixir
defmodule MyAppWeb.Admin.Fields.CodeField do
  @config_schema [
    rows: [
      doc: "Number of visible text lines",
      type: :non_neg_integer,
      default: 10
    ]
  ]

  @moduledoc """
  Custom Backpex field for syntax-highlighted code editing.
  """
  use Backpex.Field, config_schema: @config_schema

  @impl Backpex.Field
  def render_value(assigns) do
    field_value = Map.get(assigns.item, assigns.name)

    ~H"""
    <pre class="overflow-auto"><%= field_value %></pre>
    """
  end

  @impl Backpex.Field
  def render_form(assigns) do
    field_value = assigns.form[assigns.name]
    content = (field_value && field_value.value) || ""

    assigns = assign(assigns, :content, content)

    ~H"""
    <div>
      <Layout.field_container>
        <:label>
          <Layout.input_label for={@form[@name]} text={@field_options[:label]} />
        </:label>

        <!-- ExEditor Component -->
        <div class="border border-gray-300 rounded-lg overflow-hidden mb-2 h-96">
          <.live_component
            module={ExEditorWeb.LiveEditor}
            id={"editor_#{@name}"}
            content={@content}
            language={:elixir}
            on_change="code_changed"
            debounce={100}
          />
        </div>

        <!-- Hidden input for form submission -->
        <input
          type="hidden"
          name={@form[@name].name}
          value={@content}
          id={"#{@form[@name].id}_editor_sync"}
          phx-hook="EditorFormSync"
          data-field-id={@form[@name].id}
        />

        <!-- Error display -->
        <%= if Enum.any?(@form[@name].errors) do %>
          <div class="text-sm text-red-600 mt-1">
            {raw error_messages(@form[@name].errors)}
          </div>
        <% end %>
      </Layout.field_container>
    </div>
    """
  end

  defp error_messages(errors) do
    errors
    |> Enum.map(&Backpex.Field.translate_error_fun(%{}, %{}).(&1))
    |> Enum.map(&"• #{&1}")
    |> Enum.join("<br>")
  end
end
```

### Using the Custom Field in a Backpex Resource

```elixir
defmodule MyAppWeb.Admin.CodeSnippetLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: CodeSnippet,
      repo: MyApp.Repo,
      update_changeset: &CodeSnippet.changeset/3,
      create_changeset: &CodeSnippet.changeset/3
    ]

  @impl Backpex.LiveResource
  def fields do
    [
      name: %{
        module: Backpex.Fields.Text,
        label: "Name"
      },
      code: %{
        module: MyAppWeb.Admin.Fields.CodeField,
        label: "Code",
        rows: 15
      }
    ]
  end
end
```

### Form Synchronization Hook

The `EditorFormSync` hook keeps the editor content synchronized with the form input:

```javascript
// assets/js/hooks/editor_form_sync.js
export default {
  mounted() {
    // Find the editor and form input
    const editor = document.querySelector('[phx-hook="EditorHook"]');
    if (!editor) return;

    const textarea = editor.querySelector('.ex-editor-textarea');
    const fieldId = this.el.dataset.fieldId;
    const syncInput = document.querySelector(`[data-field-id="${fieldId}"]`);

    // Sync textarea changes to hidden input
    textarea.addEventListener('input', () => {
      syncInput.value = textarea.value;
    });

    // Trigger validation on blur
    textarea.addEventListener('blur', () => {
      syncInput.dispatchEvent(new Event('change'));
    });
  }
};
```

## Plugin System

ExEditor supports plugins for extending editor functionality:

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

## Incremental Diffs for Performance

ExEditor uses incremental diffs instead of sending full content on every change:

- **Default debounce**: 50ms (highly responsive)
- **Payload size**: Tiny `{from, to, text}` instead of full content
- **Server processing**: Efficient `apply_diff/4` function
- **Safety sync**: Full content on blur/paste events

This ensures high performance even with large documents.

## Troubleshooting

### Editor Content Not Syncing

Ensure the `on_change` event name matches your `handle_info/2` callback:

```elixir
# In component
on_change="code_changed"

# In LiveView
def handle_info({:code_changed, %{content: new_code}}, socket) do
  {:noreply, assign(socket, :code, new_code)}
end
```

### Backpex Form Not Saving

Verify the `EditorFormSync` hook is loaded and the hidden input has correct attributes:

```html
<input
  type="hidden"
  name={@form[@name].name}
  phx-hook="EditorFormSync"
  data-field-id={@form[@name].id}
/>
```

### Scroll Sync Issues

Both layers should have identical styling (font, padding, line-height). Check that no CSS is overriding the editor styles.

### Highlighting Not Applied

Verify the highlighter is set correctly and CSS classes are available:

```elixir
editor = Editor.set_highlighter(editor, ExEditor.Highlighters.Elixir)
# Ensure @import "ex_editor/css/editor" is in your stylesheet
```

## Demo Application

See the `demo/` directory in the ExEditor repository for complete working examples:

- **Main demo**: Simple LiveView editor with side-by-side preview
- **Backpex admin**: Full CRUD with custom CodeField and JsonField types

To run the demo:

```bash
cd demo
mix setup
mix phx.server
```

Then visit:
- [http://localhost:4000](http://localhost:4000) - Main editor demo
- [http://localhost:4000/admin/code_snippets](http://localhost:4000/admin/code_snippets) - Backpex admin panel