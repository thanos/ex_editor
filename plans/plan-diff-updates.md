# Plan: Incremental Diffs Instead of Typing Mode

## Context
The user is unhappy with the "typing mode" UX — when typing, the syntax-highlighted layer hides (opacity 0) and raw unhighlighted text shows, then highlighting fades back in after 2 seconds of inactivity. This feels jarring. The fix: send tiny diffs on a 50ms debounce instead of full content on 2000ms. The highlight layer stays visible at all times, lagging by ~50ms rather than 2 seconds.

## Files to Modify
1. `demo/assets/js/hooks/editor.js`
2. `lib/ex_editor_web/live_editor.ex`
3. `lib/ex_editor_web/css/editor.css`
4. `lib/ex_editor/editor.ex` (new `apply_diff/4` public function)
5. `test/ex_editor_web/live_editor_event_test.exs`
6. `test/ex_editor_web/live_editor_component_test.exs` (update debounce default assertion)
7. `demo/lib/demo_web/live/editor_live.ex` (remove `debounce={2000}`)

---

## 1. JavaScript: `editor.js`

### Remove
- `showTypingMode()` method entirely
- `showHighlightMode()` method entirely
- `this.showTypingMode()` call in `onInput()`
- `this.showHighlightMode()` call in `updated()`

### Add
**In `mounted()` after existing setup:**
```javascript
this.prevValue = this.textarea.value;

// Safety full-sync on blur (corrects any divergence)
this.textarea.addEventListener("blur", () => {
  if (this.debounceTimeout) clearTimeout(this.debounceTimeout);
  this.prevValue = this.textarea.value;
  this.pushEventTo(this.el, "change", { content: this.textarea.value });
});

// Safety full-sync after paste (may replace large selections)
this.textarea.addEventListener("paste", () => {
  setTimeout(() => {
    if (this.debounceTimeout) clearTimeout(this.debounceTimeout);
    this.prevValue = this.textarea.value;
    this.pushEventTo(this.el, "change", { content: this.textarea.value });
  }, 0);
});
```

**New `computeDiff(prev, next)` method:**
```javascript
computeDiff(prev, next) {
  let from = 0;
  while (from < prev.length && from < next.length && prev[from] === next[from]) from++;
  let prevEnd = prev.length;
  let nextEnd = next.length;
  while (prevEnd > from && nextEnd > from && prev[prevEnd - 1] === next[nextEnd - 1]) {
    prevEnd--;
    nextEnd--;
  }
  return { from, to: prevEnd, text: next.slice(from, nextEnd) };
},
```

**Updated `scheduleSync()`** — send diff not full content, use 50ms default:
```javascript
scheduleSync() {
  if (this.debounceTimeout) clearTimeout(this.debounceTimeout);
  const delay = parseInt(this.el.dataset.debounce) || 50;
  this.debounceTimeout = setTimeout(() => {
    const current = this.textarea.value;
    const diff = this.computeDiff(this.prevValue, current);
    this.prevValue = current;
    this.pushEventTo(this.el, "diff", diff);
  }, delay);
},
```

**Updated `updated()`** — no typing mode fade, just sync scroll:
```javascript
updated() {
  this.syncScroll();
},
```

**Updated `onInput()`** — remove `showTypingMode()` call:
```javascript
onInput() {
  this.updateLineNumbers();
  this.syncScroll();
  this.scheduleSync();
},
```

---

## 2. Core Module: `editor.ex`

Add a public `apply_diff/4` function (for testability and reuse):

```elixir
@doc """
Applies a text diff operation to content.

Takes the current content string and a diff `{from, to, text}` where:
- `from` - start index of changed region (0-based, character index)
- `to` - end index (exclusive) of changed region in the old content
- `text` - replacement text for that region

Returns `{:ok, new_content}` or `{:error, :out_of_bounds}` if positions are invalid.
"""
@spec apply_diff(String.t(), non_neg_integer(), non_neg_integer(), String.t()) ::
        {:ok, String.t()} | {:error, :out_of_bounds}
def apply_diff(content, from, to, inserted) do
  len = String.length(content)

  if from < 0 or to < from or to > len do
    {:error, :out_of_bounds}
  else
    prefix = String.slice(content, 0, from)
    suffix = String.slice(content, to, len - to)
    {:ok, prefix <> inserted <> suffix}
  end
end
```

---

## 3. LiveView Component: `live_editor.ex`

### Add `handle_event("diff", ...)` handler:
```elixir
def handle_event("diff", %{"from" => from, "to" => to, "text" => text}, socket)
    when is_integer(from) and is_integer(to) and is_binary(text) do
  editor = socket.assigns.editor
  current_content = Editor.get_content(editor)

  case Editor.apply_diff(current_content, from, to, text) do
    {:ok, new_content} ->
      case Editor.set_content(editor, new_content) do
        {:ok, updated_editor} ->
          if on_change = socket.assigns.on_change do
            send(socket.root_pid, {String.to_atom(on_change), %{content: new_content}})
          end
          {:noreply, assign(socket, :editor, updated_editor)}
        {:error, _reason} ->
          {:noreply, socket}
      end
    {:error, :out_of_bounds} ->
      # Positions don't match server state — silently drop; blur will re-sync
      {:noreply, socket}
  end
end
```

### Change default debounce in `mount/1`:
```elixir
# Change from 300 to 50
|> assign(:debounce, 50)
```

---

## 4. CSS: `editor.css`

### Remove (lines 65-72):
```css
/* While typing: show plain textarea text instantly, hide stale highlight */
.ex-editor-container.typing .ex-editor-highlight {
  opacity: 0;
}
.ex-editor-container.typing .ex-editor-textarea {
  -webkit-text-fill-color: #d4d4d4;
}
```

### Remove transition on highlight layer (line 76):
```css
transition: opacity 0.08s ease-in;
```
The highlight layer is always opacity: 1; transitions are no longer needed.

---

## 5. Demo: `demo/lib/demo_web/live/editor_live.ex`

Remove the explicit `debounce={2000}` so it uses the new 50ms default.

---

## 6. Tests

### `live_editor_component_test.exs`
Update the default debounce assertion from `data-debounce="300"` to `data-debounce="50"`.

### `live_editor_event_test.exs`
Add tests for the diff handler and `apply_diff`:

```elixir
describe "diff event handling" do
  # Test handle_event("diff", ...) with a mounted component
  test "applies single character insertion"
  test "applies deletion"
  test "silently ignores out-of-bounds diff"
end
```

### `editor.ex` tests (existing file)
Add unit tests for `ExEditor.Editor.apply_diff/4`:
- Insert at start, middle, end
- Delete (empty replacement text)
- Replace range
- Out-of-bounds positions return `{:error, :out_of_bounds}`

---

## UX Result
| | Before | After |
|---|---|---|
| Typing feel | Plain text gap (0–2000ms) | Highlight stays, lags ~50ms |
| Payload | Full content string | `{from, to, text}` (tiny) |
| Debounce | 2000ms (demo), 300ms (default) | 50ms |
| Blur/paste | Same as typing | Full-sync for safety |
| CSS `.typing` class | Present | Removed |

## Verification
1. `mix test` — all tests should pass with updated assertions
2. Open demo at `http://localhost:4000`, type in editor — highlight stays visible at all times
3. Paste a block of code — verify highlight updates immediately after paste
4. Check Network/WS in devtools — confirm `diff` events are small vs old `change` events
