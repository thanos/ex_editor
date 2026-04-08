# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-04-07

### Added

#### LiveView Component
- `ExEditorWeb.LiveEditor` LiveComponent for embedding editors in Phoenix LiveView
- `<.live_editor />` function component with declarative API
- Double-buffer rendering: invisible textarea + visible highlighted layer
- Line numbers gutter with VS Code-inspired styling
- Fake cursor rendering with blink animation
- Scroll synchronization between layers
- Debounced content change events
- Support for `phoenix_live_view` >= 0.19.0 and `phoenix_html` >= 3.0.0

#### Infrastructure
- `ExEditor.LineNumbers` module for rendering line numbers HTML
- `ExEditor.HighlightedLines` for wrapping highlighted content line-by-line
- `lib/ex_editor_web/` directory structure for LiveView integration

#### JavaScript Hook
- `editor.js` hook (~200 lines) for scroll sync and cursor rendering
- Cursor position calculation from textarea selectionStart
- Cursor blink animation with 530ms interval
- Focus/blur event handling for cursor visibility
- Resize event handling for font re-measurement

#### CSS Styles
- Default CSS styles in `lib/ex_editor_web/css/editor.css`
- Dark and light theme support
- Read-only mode styling
- Syntax highlighting classes (VS Code inspired)
- Scrollbar styling
- Focus indicator
- Print styles

#### Documentation
- `guides/integration.md` with setup instructions and troubleshooting
- Updated README with LiveEditor component usage
- Component options table with all configuration options

### Changed

#### API
- Version bumped to 0.3.0-dev
- Added `phoenix_live_view` and `phoenix_html` as optional dependencies
- Added `files` configuration to mix.exs for Hex package
- Added `groups_for_modules` to docs for better organization

#### Demo Application
- Updated to use new LiveEditor component
- Simplified `EditorLive` to use `<.live_editor />` component
- Updated demo tests for new component architecture
- Added editor.js hook to demo assets
- Updated CSS with ExEditor styles

### Fixed
- Credo warnings: use `Enum.map_join/3`, alias ordering, nested module aliases
- Demo tests updated for new LiveEditor component

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