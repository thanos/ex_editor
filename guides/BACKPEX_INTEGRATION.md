# ExEditor with Backpex

This guide shows how to integrate ExEditor into your Backpex admin panel for syntax-highlighted code editing.

## Overview

ExEditor provides a seamless integration with Backpex as a custom field. It offers:

- **Full syntax highlighting** for code in both edit and readonly modes
- **Line numbers** with instant updates while typing
- **Responsive layout** that adapts to container size
- **Form integration** - changes are automatically synced to the form
- **Readonly display** - code is shown with syntax highlighting and line numbers on show pages
- **Performance** - incremental diffs reduce payload by 4-6x

## Installation

### 1. Add Dependencies

Ensure ExEditor is in your `mix.exs`:

```elixir
def deps do
  [
    {:ex_editor, "~> 0.3.0"},
    {:backpex, "~> 0.18.0"}
  ]
end
```

### 2. Import CSS and JavaScript

Add the ExEditor CSS to `assets/css/app.css`:

```css
@import "ex_editor/css/editor";
```

Add the hooks to `assets/js/app.js`:

```javascript
import EditorHook from "ex_editor/hooks/editor"
import EditorFormSync from "./hooks/editor_form_sync.js"

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: { EditorHook, EditorFormSync },
  // ... other config
})
```

### 3. Create the EditorFormSync Hook

Create `assets/js/hooks/editor_form_sync.js`:

```javascript
/**
 * EditorFormSync Hook
 *
 * Syncs ExEditor textarea content with a hidden form input field.
 * Watches for changes to the textarea and updates the corresponding form input.
 */
export default {
  mounted() {
    const fieldId = this.el.dataset.fieldId;
    if (!fieldId) {
      console.warn("[EditorFormSync] Missing data-field-id attribute");
      return;
    }

    // Find the editor component and textarea
    const container = document.querySelector(`[phx-hook="EditorHook"]`);
    if (!container) {
      console.warn("[EditorFormSync] No EditorHook container found");
      return;
    }

    const textarea = container.querySelector('.ex-editor-textarea');
    if (!textarea) {
      console.warn("[EditorFormSync] No textarea found");
      return;
    }

    // Sync textarea value to hidden input on input event
    const syncValue = () => {
      this.el.value = textarea.value;
      // Trigger change event so form validation works
      const event = new Event("change", { bubbles: true });
      this.el.dispatchEvent(event);
    };

    // Sync on every input change
    textarea.addEventListener("input", syncValue);

    // Also sync on blur to ensure final value is captured
    textarea.addEventListener("blur", syncValue);

    // Sync immediately on mount
    syncValue();
  },
};
```

## Creating a Code Editor Field

### Basic Implementation

Create `lib/my_app_web/admin/fields/code_editor.ex`:

```elixir
defmodule MyAppWeb.Admin.Fields.CodeEditor do
  @moduledoc """
  A Backpex field for editing code with syntax highlighting.
  """
  use Backpex.Field

  @impl Backpex.Field
  def render_value(assigns) do
    field_value = Map.get(assigns.item, assigns.name)

    # Truncate for index/resource views
    if assigns.live_action in [:index, :resource_action] do
      ~H"""
      <p class="truncate" phx-no-format><%= raw highlight_code(field_value) %></p>
      """
    else
      # Show with line numbers on show page
      render_code_with_lines(field_value)
    end
  end

  @impl Backpex.Field
  def render_form(assigns) do
    field_value = assigns.form[assigns.name]
    content = field_value && field_value.value || ""

    assigns = assign(assigns, :content, content)

    ~H"""
    <div>
      <Layout.field_container>
        <:label align={Backpex.Field.align_label(@field_options, assigns, :top)}>
          <Layout.input_label for={@form[@name]} text={@field_options[:label]} />
        </:label>

        <!-- Editor component -->
        <div class="border border-gray-300 rounded-lg overflow-hidden mb-2 h-96">
          <.live_component
            module={ExEditorWeb.LiveEditor}
            id={"editor_#{@name}"}
            content={@content}
            language={:elixir}
            debounce={100}
            readonly={@readonly}
          />
        </div>

        <!-- Hidden input for form sync -->
        <input
          type="hidden"
          name={@form[@name].name}
          value={@content}
          id={"#{@form[@name].id}_editor_sync"}
          phx-hook="EditorFormSync"
          data-field-id={@form[@name].id}
        />

        <!-- Help text -->
        <%= if help_text = Backpex.Field.help_text(@field_options, assigns) do %>
          <p class="text-sm text-gray-500 mt-1"><%= help_text %></p>
        <% end %>

        <!-- Errors -->
        <%= if Enum.any?(@form[@name].errors) do %>
          <div class="text-sm text-red-600 mt-1">
            <%= Backpex.Field.translate_errors(
              @form[@name].errors,
              Backpex.Field.translate_error_fun(@field_options, assigns)
            )
            |> Enum.map(&("• #{&1}"))
            |> Enum.join("<br>")
            |> raw() %>
          </div>
        <% end %>
      </Layout.field_container>
    </div>
    """
  end

  defp render_code_with_lines(content) do
    assigns = %{content: content}

    ~H"""
    <div class="border border-gray-300 rounded-lg overflow-hidden bg-slate-900">
      <div class="ex-editor-wrapper" style="display: flex;">
        <div class="ex-editor-gutter" style="padding-top: 8px; padding-right: 12px; padding-left: 8px; background-color: #1e293b; color: #64748b; font-family: 'Monaco', 'Menlo', monospace; font-size: 14px; line-height: 1.5; user-select: none; border-right: 1px solid #334155;">
          <%= for num <- 1..line_count(@content) do %>
            <div class="ex-editor-line-number" style="text-align: right;"><%= num %></div>
          <% end %>
        </div>
        <div class="ex-editor-code-area" style="flex: 1; overflow-x: auto;">
          <pre class="ex-editor-highlight" style="padding: 8px; margin: 0; background-color: #0f172a; color: #e2e8f0; font-family: 'Monaco', 'Menlo', monospace; font-size: 14px; line-height: 1.5; overflow: hidden;"><%= raw highlight_code(@content) %></pre>
        </div>
      </div>
    </div>
    """
  end

  defp line_count(nil), do: 1
  defp line_count(content) when is_binary(content) do
    content |> String.split("\n") |> length()
  end

  defp highlight_code(nil), do: ""
  defp highlight_code(content) do
    editor = ExEditor.Editor.new(content: content)
    editor = ExEditor.Editor.set_highlighter(editor, ExEditor.Highlighters.Elixir)
    ExEditor.Editor.get_highlighted_content(editor)
  end
end
```

### Using the Field in Your Resource

In your Backpex resource, register the field:

```elixir
defmodule MyAppWeb.Admin.CodeSnippetLive do
  use Backpex.LiveResource, ...

  @impl Backpex.LiveResource
  def fields do
    [
      name: %{
        module: Backpex.Fields.Text,
        label: "Name"
      },
      code: %{
        module: MyAppWeb.Admin.Fields.CodeEditor,
        label: "Code",
        help_text: "Enter your code with syntax highlighting"
      }
    ]
  end
end
```

## Field Configuration

You can configure the field with options:

```elixir
code: %{
  module: MyAppWeb.Admin.Fields.CodeEditor,
  label: "Code",
  help_text: "Elixir code editor",
  # Optional: validate code before saving
  validate: &validate_code/1
}
```

## Customization

### Change Language

To highlight a different language:

```elixir
# In render_form
<.live_component
  module={ExEditorWeb.LiveEditor}
  id={"editor_#{@name}"}
  content={@content}
  language={:json}  # Change to :json, :elixir, etc.
  debounce={100}
/>
```

### Adjust Editor Height

Change the container height:

```html
<div class="border border-gray-300 rounded-lg overflow-hidden mb-2 h-96">
  <!-- h-96 = 24rem = 384px, change to h-64, h-screen, etc. -->
</div>
```

### Custom Styling

Modify the dark theme colors in the gutter and highlight layer:

```html
<div class="ex-editor-gutter" style="background-color: #1e293b; color: #64748b; ...">
```

## Integration Points

### Form Submission

When the form is submitted, the editor content is automatically included through the hidden input field that's kept in sync by the EditorFormSync hook.

### Validation

Add validation to your schema changeset:

```elixir
def changeset(snippet, attrs) do
  snippet
  |> cast(attrs, [:name, :code])
  |> validate_required([:name, :code])
  |> validate_code_syntax()
end

defp validate_code_syntax(changeset) do
  case get_change(changeset, :code) do
    nil ->
      changeset
    code ->
      case ExEditor.Editor.new(content: code)
           |> ExEditor.Editor.set_highlighter(ExEditor.Highlighters.Elixir)
           |> ExEditor.Editor.get_highlighted_content() do
        "" -> add_error(changeset, :code, "Invalid code")
        _ -> changeset
      end
  end
end
```

## Troubleshooting

### Editor Not Displaying

1. Check that CSS is imported in `assets/css/app.css`
2. Verify hooks are registered in `assets/js/app.js`
3. Ensure `phx-hook="EditorHook"` is on the container

### Form Not Syncing

1. Check browser console for EditorFormSync warnings
2. Ensure `phx-hook="EditorFormSync"` is on the hidden input
3. Verify `data-field-id` attribute matches the input ID

### Syntax Highlighting Not Working

1. Check that the highlighter module is correctly set
2. Verify the language is supported (`:elixir`, `:json`)
3. Create a custom highlighter for unsupported languages

## Performance Tips

- **Debounce**: Increase debounce value for very large code snippets (default: 100ms)
- **Lazy Loading**: Only load the editor when editing (not on index/show views)
- **Content Size**: ExEditor handles files up to ~10k lines efficiently

## Example: Complete Code Snippet Resource

See the demo application for a complete working example:

```bash
cd demo
mix phx.server
# Visit http://localhost:4000/admin/code-snippets
```

The demo includes:
- Full Backpex integration
- Code editor field implementation
- Database persistence
- Form validation

## More Information

- [ExEditor Documentation](https://hexdocs.pm/ex_editor)
- [Backpex Documentation](https://hexdocs.pm/backpex)
- [Demo Application](https://github.com/thanos/ex_editor/tree/main/demo)
