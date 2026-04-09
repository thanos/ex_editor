# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-04-08

### Added

#### LiveView Component & Integration
- `ExEditorWeb.LiveEditor` LiveComponent for embedding editors in Phoenix LiveView
- `<.live_editor />` function component with declarative API
- Double-buffer rendering: invisible textarea + visible highlighted layer
- Line numbers gutter with VS Code-inspired styling (JS-managed for instant updates)
- Native browser caret for immediate visual feedback while typing
- Scroll synchronization between textarea, highlight, and gutter layers
- Debounced content change events (configurable, default 2000ms for fade-in)
- Smooth fade-in of syntax highlighting after content stabilizes
- Instant plain-text display during active typing for zero-lag feel
- Support for `phoenix_live_view` >= 0.19.0 and `phoenix_html` >= 3.0.0

#### Infrastructure
- `ExEditor.LineNumbers` module for rendering line numbers HTML
- `ExEditor.HighlightedLines` for wrapping highlighted content line-by-line
- `lib/ex_editor_web/` directory structure for LiveView integration
- `lib/ex_editor_web/css/editor.css` with complete dark/light theme support

#### JavaScript Hook
- `editor.js` hook (~95 lines) for scroll sync, line numbers, and typing mode
- Immediate line number updates on input (no server round-trip)
- Typing mode: show plain text instantly, fade in syntax highlighting after server response
- Scroll synchronization between textarea and highlight/gutter layers
- Tab key handling (insert 2 spaces)
- Focus/blur event handling
- Resize event handling for font re-measurement
- `updated()` hook callback to sync scroll after LiveView DOM patches

#### CSS Styles
- Dark theme (VS Code inspired) with proper color scheme
- Light theme support
- Syntax highlighting classes
- Focus indicator and scrollbar styling
- Print-friendly styles
- Fixed cursor alignment and line height synchronization
- Gutter line numbers with hidden scrollbar

#### Testing & Documentation
- Comprehensive test suite: 267 tests, 88.7% coverage
- 20+ component rendering tests with `phoenix_test`
- 13 event handling tests covering change event processing
- 14 LiveEditor logic tests for rendering pipeline
- Unit tests for highlighters, plugins, and core modules
- Integration with `phoenix_test` for LiveComponent testing

### Changed

#### Cursor & Visual Feedback
- **Replaced fake cursor overlay with native browser caret** - eliminates cursor disappearance on DOM patch
- **Typing mode** - plain text visible during input, syntax highlighting fades in post-debounce (UX improvement for fast typists)
- **Debounce default changed to 2000ms** - allows users to see full syntax highlighting after 2 seconds of inactivity

#### Line Numbers & Alignment
- **Line numbers now managed by JavaScript** - update immediately on input without server round-trip
- **Fixed line alignment bug** - removed newline characters between `<div>` elements that were doubling visual height
- **Heredoc string handling** - fixed Elixir highlighter to preserve line count in multi-line strings

#### Elixir Highlighter
- **Fixed heredoc line count** - added missing `\n` to heredoc token end, preventing 1-line offset after heredocs
- **Fixed multi-line string spans** - split string lines before wrapping in `<span>` to keep HTML well-formed when cut by `<div>` boundaries

#### Demo Application
- Updated to use `<.live_editor />` with 2000ms debounce and dark theme
- Showcases new typing feedback with instant plain text and delayed syntax highlighting

#### Dependencies
- Added `phoenix_test` (~> 0.2) for LiveComponent testing

### Fixed
- **Cursor position misalignment** - lines 7+ had 2-line offset due to newlines in highlighted HTML (issue #XXX)
- **Deletions not reflected in line numbers** - gutter now updates immediately via JS
- **Cursor disappeared when typing** - fake cursor was destroyed on LiveView DOM patch, replaced with native caret
- **Line numbers lagged behind typing** - now managed by JavaScript, instant updates
- **Heredoc strings shortened line count** - highlighter now preserves line structure for accurate alignment
- **Multi-line string span misalignment** - HTML spans no longer contain newlines that break line wrapping
- **0.0% coverage on behavior modules** - expected behavior (interfaces, no executable code)

### Performance
- Reduced debounce impact with typing mode: instant feedback during active editing
- Line number updates moved to JS layer: zero server latency
- Scroll sync optimization with `updated()` hook to sync after highlight layer patches

### Test Coverage
- Overall: **88.7%** (up from 79.4%)
- Core modules: 96-100% coverage
- Highlighters: 87%+ coverage
- LiveEditor component: 68.2% coverage

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