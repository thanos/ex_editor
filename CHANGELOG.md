# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [Unreleased]

### Added
- Initial library release with headless architecture
- Core `ExEditor.Document` module for line-based document management
- Core `ExEditor.Editor` module for editor state management
- Plugin system via `ExEditor.Plugin` behavior
- Comprehensive unit tests (95%+ coverage)
- Phoenix LiveView demo application
- VS Code dark theme styling in demo
- Real-time content synchronization with LiveView
- JavaScript `EditorSync` hook for cursor tracking
- Side-by-side editor and raw content view
- Comprehensive documentation and examples
- Test coverage with excoveralls
- Credo and Sobelow for code quality
- Demo application tests with LiveViewTest

### Changed
- Reorganized project structure: library at root, demo in `demo/` subdirectory
- Moved all Phoenix dependencies to demo app only
- Updated module names from `ExEditorWeb` to `DemoWeb` in demo
- Removed Phoenix dependencies from library mix.exs
- Updated formatter configuration to remove Ecto/Phoenix deps from library

### Fixed
- CSS source path to point to correct `demo_web` directory
- Demo layout to match screenshot with full-screen dark theme
- All tests passing (87 library tests + 11 demo tests)
- No compilation warnings

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

[Unreleased]: https://github.com/thanos/ex_editor/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/thanos/ex_editor/releases/tag/v0.1.0

