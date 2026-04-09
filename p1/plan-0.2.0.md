# Undo/Redo, Line Numbers, and Search (v0.2.0)

**Status**: Planned  
**Version**: 0.1.1 (current) → 0.2.0  
**Type**: Feature Addition

## Overview

Add three core features to ExEditor:
- **Undo/Redo** - Bounded history with document snapshots
- **Line Numbers** - Display helpers for UI
- **Basic Search** - Find with next/previous navigation

## Design Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| History type | Full document snapshots | Simpler implementation |
| History limit | 100 entries (bounded) | Prevents memory issues |
| Search scope | Basic find + navigation | Covers most use cases |
| Search state | Editor manages | Simpler API |
| Line numbers | Display helper only | Keeps core headless |

---

## 1. Undo/Redo System

### Architecture

```
User edits → set_content() → push current document to history
                                    ↓
User undoes → undo() ← restore previous document from history
                                    ↓
User redoes → redo() ← restore next document from history
```

### New Module: `lib/ex_editor/history.ex`

```elixir
defmodule ExEditor.History do
  @moduledoc """
  Manages undo/redo history for the editor.
  
  History stores document snapshots in a bounded list.
  The cursor points to the current position in history.
  
       [A] [B] [C] [D] [E]
                   ↑
               cursor = 3 (current state)
  
  - Pushing a new document clears everything after cursor
  - Undo moves cursor back
  - Redo moves cursor forward
  """
  
  defstruct entries: [], cursor: 0, max_size: 100
  
  @type t :: %__MODULE__{
    entries: [Document.t()],
    cursor: non_neg_integer(),
    max_size: pos_integer()
  }
  
  @doc "Creates a new empty history."
  @spec new(pos_integer()) :: t()
  def new(max_size \\ 100)
  
  @doc "Pushes a document snapshot to history. Clears redo stack."
  @spec push(t(), Document.t()) :: t()
  def push(history, document)
  
  @doc "Undoes the last change. Returns the previous document."
  @spec undo(t()) :: {:ok, Document.t(), t()} | {:error, :no_history}
  def undo(history)
  
  @doc "Redoes the last undone change. Returns the next document."
  @spec redo(t()) :: {:ok, Document.t(), t()} | {:error, :no_redo}
  def redo(history)
  
  @doc "Checks if undo is available."
  @spec can_undo?(t()) :: boolean()
  def can_undo?(history)
  
  @doc "Checks if redo is available."
  @spec can_redo?(t()) :: boolean()
  def can_redo?(history)
  
  @doc "Clears all history."
  @spec clear(t()) :: t()
  def clear(history)
end
```

### Editor Changes

**Struct:**
```elixir
defstruct [:document, :plugins, :highlighter, :options, 
           metadata: %{}, 
           history: History.new()]
```

**New functions:**
```elixir
@doc "Undoes the last content change."
@spec undo(t()) :: {:ok, t()} | {:error, :no_history}

@doc "Redoes the last undone change."
@spec redo(t()) :: {:ok, t()} | {:error, :no_redo}

@doc "Checks if undo is available."
@spec can_undo?(t()) :: boolean()

@doc "Checks if redo is available."
@spec can_redo?(t()) :: boolean()
```

**Modified `set_content/2`:**
```elixir
def set_content(%__MODULE__{} = editor, content) when is_binary(content) do
  old_content = get_content(editor)

  with {:ok, editor} <- notify_plugins(editor, :before_change, {old_content, content}) do
    # Push current document to history before change
    history = History.push(editor.history, editor.document)
    new_document = Document.from_text(content)
    editor = %{editor | document: new_document, history: history}
    notify_plugins(editor, :handle_change, {old_content, content})
  end
end
```

---

## 2. Line Numbers

### Approach

Line numbers are a **display concern**. The core library provides helpers, the UI decides how to render.

### Document Changes

**New functions:**
```elixir
@doc """
Returns lines with their line numbers.

## Example

    iex> doc = Document.from_text("line1\\nline2\\nline3")
    iex> Document.get_numbered_lines(doc)
    [{1, "line1"}, {2, "line2"}, {3, "line3"}]
"""
@spec get_numbered_lines(t()) :: [{pos_integer(), String.t()}]
def get_numbered_lines(%__MODULE__{lines: lines}) do
  lines
  |> Enum.with_index(1)
  |> Enum.map(fn {line, num} -> {num, line} end)
end

@doc """
Returns text with line number prefix.

## Example

    iex> doc = Document.from_text("line1\\nline2")
    iex> Document.to_numbered_text(doc)
    "  1: line1\\n  2: line2"
"""
@spec to_numbered_text(t()) :: String.t()
def to_numbered_text(%__MODULE__{} = doc) do
  doc
  |> get_numbered_lines()
  |> Enum.map(fn {num, line} -> 
    String.pad_leading(Integer.to_string(num), 4) <> ": " <> line
  end)
  |> Enum.join("\n")
end
```

### Demo Application

Update `editor_live.ex` to show line numbers alongside editor.

---

## 3. Basic Search

### Types

```elixir
@type position :: {line :: pos_integer(), column :: pos_integer()}
@type search_match :: {position(), matched_text :: String.t()}
@type search_state :: %{
  pattern: String.t(),
  case_sensitive: boolean(),
  matches: [search_match()],
  current_index: non_neg_integer() | nil
}
```

### Document Changes

**New function:**
```elixir
@doc """
Finds all occurrences of a pattern in the document.

## Options

  - `:case_sensitive` - Match case (default: `false`)

## Returns

List of `{{line, column}, matched_text}` tuples.

## Example

    iex> doc = Document.from_text("hello\\nworld\\nhello")
    iex> Document.find(doc, "hello")
    [{{1, 1}, "hello"}, {{3, 1}, "hello"}]
"""
@spec find(t(), String.t(), keyword()) :: [search_match()]
def find(%__MODULE__{}, pattern, opts \\ [])
```

**Implementation:**
```elixir
def find(%__MODULE__{lines: lines}, pattern, opts \\ []) do
  case_sensitive = Keyword.get(opts, :case_sensitive, false)
  regex = build_search_regex(pattern, case_sensitive)
  
  lines
  |> Enum.with_index(1)
  |> Enum.flat_map(fn {line, line_num} ->
    find_in_line(line, line_num, regex)
  end)
end

defp build_search_regex(pattern, true), do: Regex.compile!(Regex.escape(pattern))
defp build_search_regex(pattern, false), do: Regex.compile!(Regex.escape(pattern), "i")

defp find_in_line(line, line_num, regex) do
  Regex.scan(regex, line, return: :index)
  |> Enum.map(fn [{start, length}] ->
    column = start + 1
    matched = String.slice(line, start, length)
    {{line_num, column}, matched}
  end)
end
```

### Editor Changes

**Struct:**
```elixir
defstruct [:document, :plugins, :highlighter, :options, 
           metadata: %{}, 
           history: History.new(),
           search: nil]
```

**New functions:**
```elixir
@doc """
Searches for a pattern in the document.

Stores search state and returns first match.

## Options

  - `:case_sensitive` - Match case (default: `false`)
"""
@spec find(t(), String.t(), keyword()) :: {:ok, t(), search_match() | nil} | {:error, :not_found}

@doc "Moves to the next search match."
@spec find_next(t()) :: {:ok, t(), search_match()} | {:error, :no_more_matches}

@doc "Moves to the previous search match."
@spec find_previous(t()) :: {:ok, t(), search_match()} | {:error, :no_more_matches}

@doc "Clears the search state."
@spec clear_search(t()) :: t()

@doc "Returns the current match position."
@spec current_match(t()) :: search_match() | nil

@doc "Returns all matches."
@spec all_matches(t()) :: [search_match()]
```

---

## Files Changed Summary

| File | Type | Changes |
|------|------|---------|
| `lib/ex_editor/history.ex` | NEW | Undo/redo history module |
| `lib/ex_editor/document.ex` | MODIFIED | Add `find/3`, `get_numbered_lines/1`, `to_numbered_text/1` |
| `lib/ex_editor/editor.ex` | MODIFIED | Add history, search; add undo/redo/find functions |
| `test/ex_editor/history_test.exs` | NEW | History module tests |
| `test/ex_editor/document_test.exs` | MODIFIED | Add search tests |
| `test/ex_editor/editor_test.exs` | MODIFIED | Add undo/redo/search tests |
| `demo/lib/demo_web/live/editor_live.ex` | MODIFIED | Show line numbers, add undo/redo buttons, add search |
| `README.md` | MODIFIED | Document new features, update version |
| `mix.exs` | MODIFIED | Bump version to 0.2.0, if needed |

---

## Execution Checklist

| # | Task | Priority |
|---|------|----------|
| 1 | Create `History` module | High |
| 2 | Add `History` tests | High |
| 3 | Update `Editor` struct with history | High |
| 4 | Update `set_content/2` to push history | High |
| 5 | Add `undo/1`, `redo/1` functions | High |
| 6 | Add undo/redo tests to Editor | High |
| 7 | Add `Document.find/3` | High |
| 8 | Add `Document.get_numbered_lines/1` | Medium |
| 9 | Add `Document.to_numbered_text/1` | Medium |
| 10 | Add search state to `Editor` struct | High |
| 11 | Add `find/3`, `find_next/1`, `find_previous/1` | High |
| 12 | Add `clear_search/1`, `current_match/1` | High |
| 13 | Add search tests to Document | High |
| 14 | Add search tests to Editor | High |
| 15 | Update demo with line numbers | Medium |
| 16 | Add undo/redo buttons to demo | Medium |
| 17 | Add search to demo | Medium |
| 18 | Update README | Medium |
| 19 | Bump version to 0.3.0 | Medium |

---

## API Summary

### History Module

```elixir
History.new(100)                    # Create history with max 100 entries
History.push(history, document)     # Add snapshot, clear redo stack
History.undo(history)               # Get previous document
History.redo(history)               # Get next document
History.can_undo?(history)          # Check if can undo
History.can_redo?(history)          # Check if can redo
History.clear(history)              # Clear all history
```

### Editor Module (new functions)

```elixir
Editor.undo(editor)                 # {:ok, editor} | {:error, :no_history}
Editor.redo(editor)                 # {:ok, editor} | {:error, :no_redo}
Editor.can_undo?(editor)            # true | false
Editor.can_redo?(editor)            # true | false
Editor.find(editor, "pattern")      # {:ok, editor, match} | {:error, :not_found}
Editor.find_next(editor)            # {:ok, editor, match} | {:error, :no_more_matches}
Editor.find_previous(editor)        # {:ok, editor, match} | {:error, :no_more_matches}
Editor.clear_search(editor)         # editor
Editor.current_match(editor)        # {position, text} | nil
Editor.all_matches(editor)          # [{position, text}, ...]
```

### Document Module (new functions)

```elixir
Document.find(doc, "pattern")       # [{position, text}, ...]
Document.find(doc, "pattern", case_sensitive: true)
Document.get_numbered_lines(doc)    # [{1, "line1"}, {2, "line2"}, ...]
Document.to_numbered_text(doc)      # "   1: line1\n   2: line2"
```

---

## Notes

- **History is per-editor** - Each editor instance has its own undo/redo stack
- **Search state persists** - Until `clear_search/1` is called or new `find/3`
- **Line numbers are helpers** - UI decides rendering, core stays headless
- **Plugins are notified** - Undo/redo triggers `:handle_change` event
