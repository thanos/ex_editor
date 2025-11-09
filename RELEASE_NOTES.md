# Release Notes - ExEditor v0.1.0

**Release Date:** Nov 8th 2025

## Overview

ExEditor 0.1.0 is the initial release of a headless code editor library for Phoenix LiveView applications. This library provides a clean, extensible foundation for building custom code editing experiences in Elixir web applications.

## Key Features

### Core Library

**Document Management**
- Line-based document model with immutable operations
- Support for all line ending formats (LF, CRLF, CR)
- 1-indexed line numbering matching standard editors
- Comprehensive line operations: insert, delete, replace, and retrieve
- Efficient text-to-lines conversion and serialization

**Editor State Management**
- Centralized editor state with document wrapping
- Clean API for content manipulation
- Error handling with explicit result tuples
- Plugin coordination and event notification

**Plugin System**
- Behavior-based plugin architecture
- Event-driven plugin lifecycle
- Support for custom application events
- Clean separation between core and extensions

### Phoenix LiveView Integration

**Demo Application**
- Full-featured example implementation
- Real-time content synchronization via LiveView
- VS Code-inspired dark theme
- Side-by-side editor and raw content display
- Cursor position tracking
- JavaScript hooks for advanced functionality

**Architecture**
- Headless design separating logic from presentation
- LiveView-ready with PubSub support
- Extensible through plugins
- Zero dependencies in core library

## Technical Specifications

**Test Coverage**
- 95.5% overall coverage
- 66 core library tests
- 11 Phoenix LiveView integration tests
- Comprehensive doctest coverage

**Code Quality**
- Credo strict mode compliance
- Sobelow security checks passed
- Zero compiler warnings
- Complete ExDoc documentation

**Dependencies**
- Core library: Pure Elixir with no external dependencies
- Demo app: Phoenix 1.8, LiveView, Ecto, SQLite

## Project Structure

The library follows a clean separation between core functionality and demonstration:

**Core Library** (`/lib`)
- `ExEditor.Document` - Document model and operations
- `ExEditor.Editor` - Editor state management
- `ExEditor.Plugin` - Plugin behavior definition

**Demo Application** (`/demo`)
- Phoenix LiveView implementation
- JavaScript hooks for textarea synchronization
- Custom styling and theming
- Complete test coverage

## Documentation

Complete documentation is provided for all public APIs:
- Module documentation with examples
- Function documentation with type specifications
- Usage examples in README
- Architecture documentation
- Contributing guidelines

## Installation

The library is distributed as a standard Elixir package:

```elixir
def deps do
  [
    {:ex_editor, "~> 0.1.0"}
  ]
end
```

## Known Limitations

- Syntax highlighting not included (can be added via plugins)
- Line numbers require custom implementation
- Search and replace functionality not built-in
- Single document per editor instance

## Future Considerations

Potential areas for future development:
- Built-in syntax highlighting support
- Performance optimizations for large documents
- Collaborative editing features
- Additional editor primitives (undo/redo, selections)
- More comprehensive plugin examples

## Credits

ExEditor was built with the Elixir and Phoenix communities in mind, drawing inspiration from existing editor architectures while maintaining a focus on simplicity and extensibility.

## License

MIT License - See LICENSE file for full details.

