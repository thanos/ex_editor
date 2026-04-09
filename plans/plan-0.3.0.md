# ExEditor v0.3.0 Plan: LiveView Code Editor Widget

**Status:** Approved for implementation  
**Created:** 2026-04-07

---

## Goal

Create a single, seamless, editable widget that combines syntax highlighting and line numbers into one cohesive editing experience using a double-buffer technique.

---

## Architecture Overview

### Double-Buffer Pattern

```
┌─────────────────────────────────────┐
│  Container (relative positioned)    │
│  ┌───────────────────────────────┐  │
│  │ Highlighted Layer (visible)   │  │  <-- Shows syntax-highlighted code
│  │   - Addition: Line numbers    │  │      with line numbers, fake cursor
│  │   - Addition: Fake cursor     │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ Textarea Layer (invisible)    │  │  <-- Invisible but accepts input
│  │   - color: transparent        │  │      captures all keystrokes
│  │   - caret-color: auto         │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

Both layers share identical:
- Font family, size, line-height
- Padding, borders
- Scroll behavior

---

## Scope

### In Scope
- Double-buffer rendering technique
- Syntax highlighting (existing behavior, now in unified view)
- Line numbers (static display, VS Code style)
- Fake cursor rendering on highlighted layer
- Scroll synchronization between layers
- Reusable LiveComponent for library users
- Colocated JavaScript hook (~200 lines)
- Default CSS styling included in library

### Out of Scope (Future Releases)
- Code folding
- Bracket auto-closing
- Search/highlight within editor
- Multiple cursor support

---

## Decisions Confirmed

| Decision | Choice |
|----------|--------|
| JavaScript Strategy | Moderate - fake cursor on overlay |
| LiveView Component | Reusable `<.live_editor />` component |
| Feature Scope | MVP: Syntax + Line Numbers |
| Line Numbers | Static display only (not clickable) |
| Asset Location | Colocated within library package |
| JS File Structure | Single file (~200 lines) |

---

## Implementation Phases

### Phase 1: Core Infrastructure

#### 1.1 Create `ExEditor.LineNumbers` module

File: `lib/ex_editor/line_numbers.ex`

Responsibilities:
- Generate line numbers HTML from document line count
- Return HTML string with proper CSS classes
- Support optional start line (default: 1)

API:
```elixir
ExEditor.LineNumbers.render(10)
# => ~s(<div class="ex-editor-line-numbers">1\n2\n...</div>)

ExEditor.LineNumbers.render_for_document(document)
# Uses Document.line_count/1
```

#### 1.2 Update Highlighter Integration

Option A: Keep existing `highlight/1` as-is
- Wrap output line-by-line in post-processing
- Simpler, no highlighter API changes

Option B: Add optional `highlight_with_lines/1` callback
- More efficient for large docs
- Requires highlighter updates

**Decision:** Start with Option A (post-processing), evaluate performance.

#### 1.3 Create `ExEditorWeb` Directory Structure

```
lib/ex_editor_web/
  live_editor.ex          # LiveComponent
  hooks/
    editor.js             # JavaScript hook
  css/
    editor.css            # Default styles
```

Update mix.exs to include these paths in hex package.

---

### Phase 2: LiveView Component

#### 2.1 Create `ExEditorWeb.LiveEditor` Component

File: `lib/ex_editor_web/live_editor.ex`

Public API:
```elixir
<.live_editor
  id="code-editor"
  content={@code}
  language={:elixir}
  on_change="code_changed"
  readonly={false}
  line_numbers={true}
/>
```

Or with existing editor:
```elixir
<.live_editor
  id="code-editor"
  editor={@editor}
  on_change="editor_changed"
/>
```

Component responsibilities:
- Accept content OR editor struct as prop
- Create/manage internal editor state
- Render double-buffer layout
- Emit change events (debounced)
- Handle undo/redo events

#### 2.2 Component Template Structure

```heex
<div id={@id} class="ex-editor-container" phx-hook="EditorHook">
  <div class="ex-editor-wrapper relative">
    <!-- Line numbers gutter -->
    <div class="ex-editor-line-numbers">
      <%= render_line_numbers(@editor) %>
    </div>
    
    <!-- Highlighted layer (visible) -->
    <pre class="ex-editor-highlight">
      <%= render_highlighted(@editor) %>
      <!-- Fake cursor rendered by JS -->
    </pre>
    
    <!-- Textarea layer (invisible) -->
    <textarea
      class="ex-editor-textarea"
      phx-change="change"
      phx-debounce="300"
    ><%= get_content(@editor) %></textarea>
  </div>
</div>
```

#### 2.3 Event Handlers

```elixir
def handle_event("change", %{"value" => content}, socket) do
  editor = socket.assigns.editor
  {:ok, editor} = Editor.set_content(editor, content)
  
  if on_change = socket.assigns.on_change do
    send(self(), {on_change, content})
  end
  
  {:noreply, assign(socket, :editor, editor)}
end
```

---

### Phase 3: JavaScript Hook

#### 3.1 Create `lib/ex_editor_web/hooks/editor.js`

Single file, ~200 lines:

```javascript
export default {
  mounted() {
    this.textarea = this.el.querySelector('.ex-editor-textarea');
    this.highlight = this.el.querySelector('.ex-editor-highlight');
    this.cursorEl = null;
    
    this.setupFakeCursor();
    this.bindEvents();
    this.syncDimensions();
  },
  
  destroyed() {
    this.unbindEvents();
    if (this.cursorEl) this.cursorEl.remove();
  },
  
  setupFakeCursor() {
    this.cursorEl = document.createElement('div');
    this.cursorEl.className = 'ex-editor-cursor';
    this.highlight.appendChild(this.cursorEl);
    this.startCursorBlink();
  },
  
  bindEvents() {
    this.textarea.addEventListener('input', this.handleInput.bind(this));
    this.textarea.addEventListener('scroll', this.handleScroll.bind(this));
    this.textarea.addEventListener('click', this.updateCursor.bind(this));
    this.textarea.addEventListener('keyup', this.updateCursor.bind(this));
  },
  
  handleScroll() {
    this.highlight.scrollTop = this.textarea.scrollTop;
    this.highlight.scrollLeft = this.textarea.scrollLeft;
  },
  
  updateCursor() {
    const pos = this.textarea.selectionStart;
    const coords = this.getCursorCoords(pos);
    this.cursorEl.style.top = coords.y + 'px';
    this.cursorEl.style.left = coords.x + 'px';
    this.restartCursorBlink();
  },
  
  getCursorCoords(position) {
    const content = this.textarea.value.substring(0, position);
    const lines = content.split('\n');
    const lineNum = lines.length;
    const colNum = lines[lines.length - 1].length;
    
    const lineHeight = this.getLineHeight();
    const charWidth = this.getCharWidth();
    
    const y = (lineNum - 1) * lineHeight;
    const x = colNum * charWidth;
    
    return { x, y };
  },
  
  getLineHeight() {
    const computed = window.getComputedStyle(this.textarea);
    return parseFloat(computed.lineHeight);
  },
  
  getCharWidth() {
    // Monospace assumption
    const computed = window.getComputedStyle(this.textarea);
    const fontSize = parseFloat(computed.fontSize);
    return fontSize * 0.6; // Approximate for monospace
  },
  
  startCursorBlink() {
    this.cursorEl.style.opacity = '1';
    this.blinkInterval = setInterval(() => {
      this.cursorEl.style.opacity = 
        this.cursorEl.style.opacity === '0' ? '1' : '0';
    }, 530);
  },
  
  restartCursorBlink() {
    this.cursorEl.style.opacity = '1';
    clearInterval(this.blinkInterval);
    this.startCursorBlink();
  }
};
```

#### 3.2 Key Features

| Feature | Implementation |
|---------|---------------|
| Scroll sync | Mirror scrollTop/scrollLeft between layers |
| Cursor position | Calculate from selectionStart + font metrics |
| Cursor blink | CSS animation + JS interval fallback |
| Type-to-update | Debounced push to server (handled by LiveView) |
| Tab handling | Prevent default, insert spaces |

#### 3.3 Performance Considerations

- Debounce cursor updates (don't fire on every keypress for fast typists)
- Use `requestAnimationFrame` for scroll sync
- Cache char width measurement on mount
- Consider `ResizeObserver` for container size changes

---

### Phase 4: Styling

#### 4.1 Default CSS

File: `lib/ex_editor_web/css/editor.css`

```css
.ex-editor-container {
  position: relative;
  font-family: 'Menlo', 'Monaco', 'Courier New', monospace;
  font-size: 14px;
  line-height: 1.5;
  background: #1e1e1e;
  color: #d4d4d4;
  border: 1px solid #3e3e3e;
  border-radius: 0.5rem;
  overflow: hidden;
}

.ex-editor-wrapper {
  position: relative;
  height: 100%;
}

.ex-editor-line-numbers {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3rem;
  padding: 1rem 0.5rem;
  text-align: right;
  color: #858585;
  user-select: none;
  pointer-events: none;
  border-right: 1px solid #3e3e3e;
  background: #252525;
}

.ex-editor-highlight {
  position: absolute;
  top: 0;
  left: 3.5rem; /* line numbers width + padding */
  right: 0;
  bottom: 0;
  padding: 1rem;
  margin: 0;
  overflow: auto;
  white-space: pre;
  pointer-events: none; /* Let clicks through to textarea */
}

.ex-editor-textarea {
  position: absolute;
  top: 0;
  left: 3.5rem;
  right: 0;
  bottom: 0;
  padding: 1rem;
  margin: 0;
  background: transparent;
  color: transparent;
  caret-color: #d4d4d4;
  border: none;
  outline: none;
  resize: none;
  font-family: inherit;
  font-size: inherit;
  line-height: inherit;
  white-space: pre;
  overflow: auto;
}

.ex-editor-cursor {
  position: absolute;
  width: 2px;
  height: 1.2em;
  background: #d4d4d4;
  pointer-events: none;
  transition: opacity 0.1s;
}

@keyframes blink {
  0%, 50% { opacity: 1; }
  51%, 100% { opacity: 0; }
}

.ex-editor-cursor.blink {
  animation: blink 1s step-end infinite;
}
```

#### 4.2 Tailwind Alternative

For projects using Tailwind, document equivalent classes:

```elixir
# In component, allow theme prop
<.live_editor theme="tailwind" />
```

Include Tailwind snippet in docs for custom styling.

---

### Phase 5: Testing & Documentation

#### 5.1 Unit Tests

| Test File | Coverage |
|-----------|----------|
| `test/ex_editor/line_numbers_test.exs` | Line number generation |
| `test/ex_editor_web/live_editor_test.exs` | Component rendering, events |

Tests to write:
```elixir
# LineNumbers
test "renders correct number of lines"
test "supports custom start line"
test "generates valid HTML structure"

# LiveEditor
test "renders with content string"
test "renders with editor struct"
test "emits change events"
test "integrates with highlighter"
test "shows line numbers when enabled"
test "hides line numbers when disabled"
```

#### 5.2 Integration Tests (Demo)

File: `demo/test/demo_web/live/editor_live_test.exs`

Update to test:
- Component renders without errors
- Content changes propagate correctly
- Cursor position displays
- Line numbers match content

#### 5.3 Documentation Updates

**README.md additions:**
```markdown
## Phoenix LiveView Component

ExEditor includes a ready-to-use LiveView component:

\`\`\`elixir
<.live_editor
  id="my-editor"
  content={@code}
  language={:elixir}
  on_change="code_changed"
/>
\`\`\`

### Setup

1. Import the JavaScript hook:

\`\`\`javascript
// assets/js/app.js
import EditorHook from "ex_editor/hooks/editor"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { EditorHook }
})
\`\`\`

2. Include the CSS:

\`\`\`css
/* assets/css/app.css */
@import "ex_editor/css/editor";
\`\`\`
```

**Create `guides/integration.md`:**
- Detailed setup instructions
- Customization options
- Theming guide
- Troubleshooting common issues

**Update Hex.exs docs:**
```elixir
defp docs do
  [
    main: "readme",
    extras: [
      "README.md",
      "CHANGELOG.md",
      "guides/plugins.md",
      "guides/integration.md"  # NEW
    ]
  ]
end
```

---

## File Structure Summary

### New Files

```
lib/
  ex_editor/
    line_numbers.ex                    # Line number generation

  ex_editor_web/                       # NEW directory
    live_editor.ex                     # LiveComponent
    hooks/
      editor.js                        # JS hook (~200 lines)
    css/
      editor.css                       # Default styles

plans/
  plan-0.3.0.md                        # This file

guides/
  integration.md                       # NEW - Setup guide
```

### Modified Files

```
mix.exs                                # Include ex_editor_web in package
README.md                              # Add component usage section

demo/lib/demo_web/live/editor_live.ex  # Update to use <.live_editor>
demo/assets/js/app.js                  # Import EditorHook
demo/assets/css/app.css                # Import editor.css
```

---

## API Usage Example

### Library User's LiveView

```elixir
# lib/my_app_web/live/editor_live.ex
defmodule MyAppWeb.EditorLive do
  use MyAppWeb, :live_view
  
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :code, "def hello, do: :world")}
  end
  
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-8">
      <h1>My Code Editor</h1>
      
      <.live_editor
        id="code-editor"
        content={@code}
        language={:elixir}
        on_change="code_changed"
        class="h-96"
      />
    </div>
    """
  end
  
  def handle_event("code_changed", %{"content" => new_code}, socket) do
    # Handle code changes
    {:noreply, assign(socket, :code, new_code)}
  end
end
```

### Library User's JavaScript

```javascript
// assets/js/app.js
import EditorHook from "ex_editor/hooks/editor"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { EditorHook }
})
```

### Library User's CSS

```css
/* assets/css/app.css */
@import "ex_editor/css/editor";

/* Or with Tailwind: */
@import "tailwindcss";
/* Then customize by overriding .ex-editor-* classes */
```

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Cursor position drift on non-monospace fonts | Medium | High | Document monospace requirement; add validation |
| Scroll sync jitter on fast scroll | Low | Medium | Debounce scroll events; use requestAnimationFrame |
| Mobile touch behavior issues | Medium | Medium | Test on iOS/Android; consider fallback mode |
| Hex package asset bundling | Low | High | Verify hex publishing includes JS/CSS files |
| Performance on large files (>10k lines) | Medium | Medium | Virtualization in future version; add warning in docs |

---

## Timeline Estimate

| Phase | Sessions |
|-------|----------|
| Phase 1: Core Infrastructure | 2-3 |
| Phase 2: LiveView Component | 2-3 |
| Phase 3: JavaScript Hook | 2-3 |
| Phase 4: Styling | 1 |
| Phase 5: Testing & Docs | 1-2 |
| **Total** | **8-12 sessions** |

---

## Breaking Changes

**None.** v0.3.0 is purely additive. The existing API (`ExEditor.Editor`, `ExEditor.Document`, `ExEditor.Highlighter`, etc.) remains unchanged and fully compatible.

Users can optionally adopt the new `<.live_editor />` component, or continue using the core editor API directly.

---

## Success Criteria

- [ ] Editor displays single unified view (not split panels)
- [ ] Line numbers visible and accurate
- [ ] Syntax highlighting works in real-time
- [ ] Cursor visible and blinks correctly
- [ ] Scroll sync works smoothly
- [ ] Component is reusable with documented API
- [ ] JS hook imports and functions without errors
- [ ] Demo app uses new component successfully
- [ ] All tests pass (existing + new)
- [ ] Documentation complete and accurate

---

## Notes

- Font must be monospace for cursor positioning to work correctly
- Tested fonts: Menlo, Monaco, Consolas, 'Courier New', monospace fallback
- Cursor blink uses CSS animation with JS fallback for older browsers
- Future consideration: virtualized line rendering for very large files