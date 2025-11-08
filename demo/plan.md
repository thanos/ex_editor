# ExEditor Reorganization Plan

Goal: Transform ExEditor into a reusable library with a separate demo Phoenix app (like Backpex structure)

## Phase 1: Create Library Structure
- [x] Move core modules to clean library structure
  - Keep only: Document, Editor, Plugin system at root lib/ex_editor/
  - Remove all Phoenix-specific code from library
- [x] Create library mix.exs (no Phoenix deps)
- [x] Create library-only README

## Phase 2: Create Demo Phoenix App
- [x] Generate new Phoenix app in demo/ directory
- [x] Configure demo to use path dependency: `{:ex_editor, path: ".."}`
- [x] Move EditorLive, templates, layouts to demo
- [x] Move hooks (assets/js/hooks/) to demo
- [x] Move CSS (assets/css/) to demo

## Phase 3: Move Phoenix-Specific Files
- [x] Move priv/ to demo/priv/
- [x] Move test/ files appropriately (lib tests to root, Phoenix tests to demo)
- [x] Move current config/ to demo/config/
- [x] Update .formatter.exs for both projects

## Phase 4: Fix Paths and Imports
- [x] Update all module references in demo
- [x] Update all import/alias statements
- [x] Fix asset paths in demo layouts
- [x] Ensure demo compiles cleanly
- [x] Fix CSS @source path to point to demo_web
- [x] Fix demo layout to match screenshot (full-screen dark theme)

## Phase 5: Test and Document
- [x] Start demo server and verify editor works
- [x] Verify layout matches screenshot design
- [ ] Fix cursor tracking bug in EditorLive
- [ ] Update root README with library usage
- [ ] Create demo/README with demo-specific instructions
- [ ] Add hex package metadata to root mix.exs
- [ ] Update CHANGELOG.md

