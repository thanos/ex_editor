# ExEditor - Headless Code Editor for Phoenix LiveView

## Project Goal
Build a **pure Elixir headless editor** inspired by Tiptap's architecture, but LiveView-native.
First release: A LiveView component that transforms a textarea into a code editor with line numbering.

## Detailed Implementation Plan

### Phase 1: Core Architecture (Steps 1-5)
- [x] Clone reference repo and analyze
- [x] Generate Phoenix project for development
- [x] Create plan.md and start server
- [x] Replace home page with static editor mockup
- [x] Create core ExEditor modules:
  - `ExEditor.Document` - Document state (lines, content)
  - `ExEditor.Editor` - Main editor state management
  - `ExEditor.Plugin` - Behaviour for plugins

### Phase 2: LiveView Component (Steps 6-8)
- [x] Create `ExEditor.LiveComponent`
  - Shadow textarea for actual input
  - Overlay div for rendered content
  - Line numbering display
  - Handle textarea events (input, keydown, scroll)
  - Sync scroll position between textarea and overlay

### Phase 3: Line Numbering Plugin (Step 9)
- [x] Create `ExEditor.Plugins.LineNumbers`
  - Calculate line numbers from document
  - Render line gutter
  - Sync with content height

### Phase 4: Demo & Integration (Steps 10-13)
- [x] Create demo LiveView at `/editor`
  - JSON editing example
  - Real-time updates
  - Show/hide line numbers toggle
- [x] Match `app.css` to code editor theme
- [x] Match `root.html.heex` to design (force dark theme)
- [x] Match `<Layouts.app>` to design (minimal, code-focused)

### Phase 5: Router & Testing (Steps 14-15)
- [x] Update router to replace root route with `/editor`
- [x] Visit and verify functionality

### Reserved Steps
- [x] All steps completed successfully!

## Technical Architecture Notes

### Shadow Textarea Approach
```
┌─────────────────────────────────┐
│  <div class="ex-editor">        │
│    <textarea> (hidden)          │ ← Actual input, accessibility
│    <div class="overlay">        │ ← Rendered with line numbers
│      <div class="gutter">1</div>│
│      <div class="line">...</div>│
│    </div>                        │
└─────────────────────────────────┘
```

### Plugin System
Plugins implement `ExEditor.Plugin` behaviour:
- `c:render/2` - Render plugin UI
- `c:handle_change/2` - React to document changes

## Design Choice
**VS Code dark theme** with monospace font, subtle line highlighting

