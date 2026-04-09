# ExEditor v0.3.0 - Release Notes

**Release Date:** April 8, 2026

## Overview

ExEditor v0.3.0 delivers a complete, production-ready Phoenix LiveView code editor component with significant UX improvements, architectural refinements, and comprehensive test coverage (88.7%).

## Key Improvements

### 🎯 Zero-Lag Typing Experience
- **Typing Mode**: Plain text appears instantly while you type. Syntax highlighting fades in smoothly after 2 seconds of inactivity
- **Native Caret**: Uses browser's native cursor instead of JavaScript overlay (eliminates cursor disappearance bug)
- **Instant Line Numbers**: Line count updates immediately via JavaScript, no server round-trip needed

### ✨ Bug Fixes
- **Fixed cursor alignment** - Removed newline characters between highlighted line divs that were causing 2-line offset after line 7
- **Fixed heredoc line count** - Elixir highlighter now preserves line structure in multi-line strings
- **Fixed deletions** - Line numbers now reflect content changes instantly
- **Fixed HTML well-formedness** - Multi-line string spans no longer contain newlines that break div wrapping

### 📦 Complete LiveView Integration
- Ready-to-use `<.live_editor />` component with minimal configuration
- Double-buffer rendering for seamless syntax highlighting
- Scroll synchronization across textarea, highlight layer, and line numbers
- Configurable debounce, language, theming, and more

### 🧪 Excellent Test Coverage
- **267 tests** (12 doctests + 255 unit tests)
- **88.7% coverage** across all modules
- 20+ component rendering tests
- 13 event handling tests
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
  debounce={2000}
/>
```

The component handles:
- Instant line numbers via JavaScript
- Syntax highlighting after debounce
- Scroll synchronization
- Native cursor with immediate visual feedback

## Architecture Highlights

**Data Model**: Elixir owns all content, history, plugins, and syntax highlighting logic
**UI Layer**: JavaScript manages cursor, scroll, line numbers, and typing mode
**Rendering**: Server sends syntax-highlighted HTML on debounce timer, no real-time round-trips

## What's Next?

Future versions may include:
- Code folding
- Bracket auto-closing
- Search/find within editor
- Multiple cursor support
- Virtualized rendering for 10k+ line files

## Breaking Changes

None. v0.3.0 is fully backward compatible with v0.2.0.

## Contributors

Special thanks to the testing and documentation improvements in this release.

---

**[Hex Package](https://hex.pm/packages/ex_editor) | [Documentation](https://hexdocs.pm/ex_editor) | [GitHub](https://github.com/thanos/ex_editor)**
