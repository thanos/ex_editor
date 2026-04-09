# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-04-09

### Added

#### LiveView Component & Integration
- `ExEditorWeb.LiveEditor` LiveComponent for embedding editors in Phoenix LiveView
- `<.live_editor />` function component with declarative API
- Double-buffer rendering: invisible textarea + visible highlighted layer
- Line numbers gutter with VS Code-inspired styling (JS-managed for instant updates)
- Native browser caret for immediate visual feedback while typing
- Scroll synchronization between textarea, highlight, and gutter layers
- Support for `phoenix_live_view` >= 0.19.0 and `phoenix_html` >= 3.0.0

#### Content Synchronization (Incremental Diffs)
- `Editor.apply_diff/4` function for applying text operations (insert/delete/replace)
- Incremental diff events: send only `{from, to, text}` instead of full content
- ~4-6x smaller payloads (typical keystroke: ~20 bytes vs ~120 bytes)
- Faster server processing with smaller deltas
- Debounce for diff batching (default 50ms, configurable)
- Safety full-sync on blur and paste events to prevent divergence

#### JavaScript Hook
- `editor.js` hook (~130 lines) for scroll sync, line numbers, and diff computation
- `computeDiff()` algorithm to find minimal changes between content versions
- Immediate line number updates on input (no server round-trip)
- Scroll synchronization between textarea and highlight/gutter layers
- Tab key handling (insert 2 spaces)
- Blur/paste event handling for full-content safety sync
- `updated()` hook callback to sync scroll after LiveView DOM patches

#### CSS Styles
- Dark theme (VS Code inspired) with proper color scheme
- Light theme support
- Syntax highlighting classes
- Focus indicator and scrollbar styling
- Print-friendly styles
- Fixed cursor alignment and line height synchronization
- Gutter line numbers with hidden scrollbar

#### Infrastructure
- `ExEditor.LineNumbers` module for rendering line numbers HTML
- `ExEditor.HighlightedLines` for wrapping highlighted content line-by-line
- `lib/ex_editor_web/` directory structure for LiveView integration
- `lib/ex_editor_web/css/editor.css` with complete dark/light theme support

#### Backpex Integration
- Custom field implementation for Backpex admin panels
- Syntax-highlighted code editing in admin forms
- Readonly display with line numbers on show pages
- Form sync hook for automatic field value updates
- Ready-to-use example in demo application
- Documentation with complete integration guide

#### Testing & Documentation
- Comprehensive test suite: 285 tests, 88.7%+ coverage
- 11 unit tests for `Editor.apply_diff/4` with edge cases
- 20+ component rendering tests with `phoenix_test`
- 13 event handling tests for diff processing
- 14 LiveEditor logic tests for rendering pipeline
- Unit tests for highlighters, plugins, and core modules
- Behavior modules (Highlighter, Plugin) with extensive examples
- Integration with `phoenix_test` for LiveComponent testing
- Backpex integration guide with example field implementation

### Changed

#### Content Synchronization (Major UX Improvement)
- **Replaced typing mode with incremental diffs** - highlight layer always visible, lags ~50ms instead of 2 seconds
- **No more unhighlighted gap** - users see previous syntax highlighting while new highlighting loads
- **Default debounce: 2000ms → 50ms** - now debounces diffs (small packets), not highlight fades
- **Event name changed** - `"change"` (full content) now only on blur/paste; `"diff"` (incremental) on every keystroke

#### Cursor & Visual Feedback
- **Replaced fake cursor overlay with native browser caret** - eliminates cursor disappearance on DOM patch
- **Removed typing mode CSS** - no more opacity transitions or text-fill-color hacks
- **Instant highlighting visibility** - highlight layer always at opacity 1

#### Line Numbers & Alignment
- **Line numbers now managed by JavaScript** - update immediately on input without server round-trip
- **Fixed line alignment bug** - removed newline characters between `<div>` elements that were doubling visual height
- **Heredoc string handling** - fixed Elixir highlighter to preserve line count in multi-line strings

#### Elixir Highlighter
- **Fixed heredoc line count** - added missing `\n` to heredoc token end, preventing 1-line offset after heredocs
- **Fixed multi-line string spans** - split string lines before wrapping in `<span>` to keep HTML well-formed when cut by `<div>` boundaries

#### Demo Application
- Updated to use incremental diffs with 50ms debounce
- Layout: editor and raw content preview side by side with aligned headings
- Removed typing mode transition visuals

#### Dependencies
- Added `phoenix_test` (~> 0.2) for LiveComponent testing

### Fixed
- **Cursor position misalignment** - lines 7+ had 2-line offset due to newlines in highlighted HTML
- **Deletions not reflected in line numbers** - gutter now updates immediately via JS
- **Cursor disappeared when typing** - fake cursor was destroyed on LiveView DOM patch, replaced with native caret
- **Line numbers lagged behind typing** - now managed by JavaScript, instant updates
- **Highlighting gap during typing** - replaced with incremental diffs that keep highlight visible at all times
- **Heredoc strings shortened line count** - highlighter now preserves line structure for accurate alignment
- **Multi-line string span misalignment** - HTML spans no longer contain newlines that break line wrapping
- **0.0% coverage on behavior modules** - expected behavior (interfaces, no executable code)

### Performance
- **Payload size: 4-6x smaller** - incremental diffs (avg ~20 bytes) vs full content (avg ~120 bytes)
- **Server processing: faster** - smaller deltas reduce CPU and memory per event
- **UX latency: 50ms vs 2000ms** - highlight layer lags by debounce delay, not server round-trip
- **Line number updates moved to JS layer** - zero server latency
- **Scroll sync optimization** with `updated()` hook to sync after highlight layer patches

### Test Coverage
- Overall: **88.7%** (up from 79.4%)
- Core modules: 96-100% coverage
- Highlighters: 87%+ coverage
- LiveEditor component: 68.2% coverage
- Total tests: **285** (12 doctests + 273 unit tests)

## [0.2.0] - 2026-04-02

### Added
- Initial content is now pushed to history on editor creation, enabling undo to original content
- Plugin validation in `new/1` - raises `ArgumentError` for invalid plugins
- Comprehensive test coverage for undo/redo with plugins
- Tests for `notify/3` with multiple plugins in chain
- Tests for `History.push` with `max_size: 1` edge case
- GitHub Actions CI workflow with matrix testing (Elixir 1.15-1.20, OTP 26-29)
- GitHub Actions release workflow with version validation and Hex publishing
- GitHub Actions Fly.io deployment workflow

### Changed
- `Editor.new/1` now returns a bare `%Editor{}` struct instead of `{:ok, editor}`
- `can_undo?/1` requires at least two content states in history (cursor >= 2)
- Improved undo/redo to properly capture old/new content for plugin notifications
- Plugin errors during `:handle_change` now preserve intermediate plugin state
- Removed defensive `function_exported?` checks in plugin notification (plugins validated at creation)
- Updated all test plugins to use `@impl true` for callback functions

### Fixed
- `undo/1` and `redo/1` now pass correct `{old_content, new_content}` to plugins (was passing `nil` for old content)
- Plugin state is now preserved when a plugin errors during `:handle_change` chain
- Removed debug `dbg()` call from production code in demo app
- Fixed deprecated `:layout` option in Backpex LiveResource usage
- Fixed demo tests to match actual element IDs

## [0.1.0] - 2024-01-08

### Added
- Initial release of ExEditor
- Document model with line operations (insert, delete, replace, get)
- Editor state manager with plugin support
- Plugin behavior for extensibility
- Line-based text representation
- Support for multiple line ending formats (\n, \r\n, \r)
- 1-based line indexing matching common editors
- Error handling with {:ok, result} | {:error, reason} tuples
- Comprehensive documentation with examples
- Phoenix LiveView demo application
- Real-time editing capabilities
- JavaScript hooks for advanced features
- VS Code inspired dark theme
- 95%+ test coverage
- MIT License

[0.3.0]: https://github.com/thanos/ex_editor/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/thanos/ex_editor/releases/tag/v0.2.0
[0.1.0]: https://github.com/thanos/ex_editor/releases/tag/v0.1.0