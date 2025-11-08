# ExEditor

A headless code editor for Phoenix LiveView, inspired by Tiptap's architecture. ExEditor provides a pure Elixir solution for building customizable text editing experiences without heavy JavaScript dependencies.

## Overview

ExEditor demonstrates a headless editor architecture using Phoenix LiveView's real-time capabilities. The project implements a shadow textarea approach where a hidden textarea handles input and accessibility while an overlay provides enhanced rendering and features.

## Features

### Core Architecture
- **Shadow Textarea Design**: Accessible textarea for keyboard input and screen readers with visual overlay for rendering
- **Pure Elixir Backend**: Server-side document state management with minimal JavaScript
- **Real-time Updates**: LiveView integration for instant content synchronization
- **Plugin System**: Extensible architecture via the `ExEditor.Plugin` behaviour

### Current Capabilities
- Live text editing with debounced updates
- Cursor position tracking
- Side-by-side content display (editor and raw output)
- Dark theme based on VS Code color scheme
- Proper keyboard navigation and accessibility

### Technical Components
- `ExEditor.Document`: Immutable document state with line-based structure
- `ExEditor.Editor`: Main state manager coordinating document and plugins
- `ExEditor.Plugin`: Behaviour module for creating editor extensions
- `EditorSync` JS Hook: Minimal JavaScript for textarea synchronization

## Architecture

The editor uses a layered approach:

```
User Input Layer (Shadow Textarea)
  - Handles all keyboard input
  - Maintains accessibility
  - Hidden from view with transparent text

Rendering Layer (Overlay)
  - Displays formatted content
  - Shows cursor position
  - Applies visual enhancements

State Layer (LiveView)
  - Manages document state
  - Coordinates plugins
  - Handles real-time updates
```

## Screenshot

A screenshot will be added here showing the editor interface with side-by-side layout.

## Installation

This is a demonstration project. To run locally:

```bash
# Clone the repository
git clone https://github.com/thanos/ex_editor.git
cd ex_editor

# Install dependencies
mix setup

# Start the Phoenix server
mix phx.server
```

Visit `http://localhost:4000` to see the editor in action.

## Project Structure

```
lib/ex_editor/
  ├── document.ex          # Document state and operations
  ├── editor.ex            # Main editor state manager
  └── plugin.ex            # Plugin behaviour definition

lib/ex_editor_web/
  └── live/
      └── editor_live.ex   # LiveView component

assets/
  └── js/
      └── hooks/
          └── editor_sync.js  # Textarea synchronization hook
```

## Development Status

This project is in active development. Current focus areas:

- Core editing functionality (complete)
- Shadow textarea architecture (complete)
- Side-by-side content display (complete)
- Plugin system foundation (in progress)
- Syntax highlighting (planned)
- Line numbering (planned)
- Code folding (planned)

## Technical Notes

### Why Shadow Textarea?

The shadow textarea approach provides several benefits:

- Native browser input handling (copy, paste, undo, redo)
- Full accessibility support (screen readers, keyboard navigation)
- No need to reimplement text editing primitives
- Works with browser extensions and password managers

### LiveView Integration

By managing state server-side through LiveView, the editor benefits from:

- Consistent state management
- Easy plugin coordination
- Simplified debugging
- Reduced client-side complexity

## Contributing

This is a demonstration project showing headless editor patterns in Phoenix LiveView. Feel free to explore the code and adapt the patterns for your own projects.

## License

This project is available as open source under the terms of the MIT License.

## Acknowledgments

Inspired by Tiptap's headless editor philosophy and adapted for the Phoenix LiveView ecosystem.
