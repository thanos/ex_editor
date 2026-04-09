# ExEditor v0.3.0 - Release Notes

**Release Date:** April 9, 2026

## Overview

ExEditor v0.3.0 delivers a complete, production-ready Phoenix LiveView code editor component with incremental diff-based content sync, native browser caret, and comprehensive test coverage (88.7%+).

## Key Improvements

### 🚀 Incremental Diff Synchronization
- **Always-Visible Highlighting**: Syntax highlighting stays visible at all times, lags by ~50ms instead of 2 seconds
- **4-6x Smaller Payloads**: Send only changed content (`{from, to, text}`) instead of full text (~20 bytes vs ~120 bytes per keystroke)
- **Faster Server Processing**: Smaller deltas reduce CPU and memory usage per event
- **Smart Sync**: Blur and paste events trigger full-content sync for safety; normal typing uses incremental diffs

### ✨ Responsive User Experience
- **Native Caret**: Uses browser's native cursor instead of JavaScript overlay (no cursor disappearance)
- **Instant Line Numbers**: Line count updates immediately via JavaScript, no server round-trip needed
- **Perfect Scroll Alignment**: Textarea, highlight layer, and gutter stay perfectly synchronized

### 🐛 Bug Fixes
- **Fixed cursor alignment** - Removed newline characters between highlighted line divs that were causing 2-line offset after line 7
- **Fixed heredoc line count** - Elixir highlighter now preserves line structure in multi-line strings
- **Fixed deletions** - Line numbers now reflect content changes instantly
- **Fixed HTML well-formedness** - Multi-line string spans no longer contain newlines that break div wrapping
- **Removed typing mode gap** - No more unhighlighted period during content sync

### 📦 Complete LiveView Integration
- Ready-to-use `<.live_editor />` component with minimal configuration
- Double-buffer rendering for seamless syntax highlighting
- Scroll synchronization across textarea, highlight layer, and line numbers
- Configurable debounce, language, theming, and more
- Built-in support for Elixir and JSON syntax highlighting

### 🧪 Excellent Test Coverage
- **285 tests** (12 doctests + 273 unit tests)
- **88.7%+ coverage** across all modules
- 11 unit tests for `Editor.apply_diff/4`
- 20+ component rendering tests
- 13 event handling tests for diff processing
- Full LiveComponent integration with `phoenix_test`

## Installation

Add to `mix.exs`:

```elixir
{:ex_editor, "~> 0.3.0"}
```

## Quick Start

```heex
<ExEditorWeb.LiveEditor.live_editor
  id="code-editor"
  content={@code}
  language={:elixir}
  on_change="code_changed"
/>
```

The component handles:
- Instant line numbers via JavaScript
- Real-time syntax highlighting with ~50ms latency
- Incremental diff synchronization (small payloads)
- Scroll synchronization
- Native cursor with immediate visual feedback

## Architecture Highlights

**Data Model**: Elixir owns all content, history, plugins, and syntax highlighting logic
**Content Sync**: Incremental diffs (`{from, to, text}`) for fast server processing and small payloads
**UI Layer**: JavaScript manages cursor, scroll, line numbers, and diff computation
**Rendering**: Server processes diffs, updates content, and sends refreshed syntax-highlighted HTML

## What's New in v0.3.0

- Complete LiveView integration with production-ready component
- Incremental diff synchronization replacing polling/full-content updates
- Native browser caret (no JS-overlay cursor)
- JavaScript-managed line numbers (instant, no server round-trip)
- Comprehensive test suite with LiveComponent testing
- Extensive behavior module documentation with multiple examples
- Demo application showcasing side-by-side editor and preview

## What's Next?

Future versions may include:
- Code folding
- Bracket auto-closing
- Search/find within editor
- Multiple cursor support
- Virtualized rendering for 10k+ line files

## Breaking Changes

None. v0.3.0 is fully backward compatible with v0.2.0.

## Performance Improvements

| Metric | Before | After |
|--------|--------|-------|
| Payload per keystroke | ~120 bytes | ~20 bytes |
| Highlighting latency | 2000+ ms | ~50 ms |
| Line number latency | 300+ ms | 0 ms (JS) |
| Network traffic | Full content | Only diffs |

---

**[Hex Package](https://hex.pm/packages/ex_editor) | [Documentation](https://hexdocs.pm/ex_editor) | [GitHub](https://github.com/thanos/ex_editor)**
