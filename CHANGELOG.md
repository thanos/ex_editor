# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

