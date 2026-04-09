# ExEditor v0.2.0

### Breaking Changes

- **`Editor.new/1` now returns a bare `%Editor{}` struct** instead of `{:ok, editor}`. This is a cleaner API since the function cannot fail. Update your code from:
  ```elixir
  {:ok, editor} = ExEditor.Editor.new(content: "hello")
  ```
  to:
  ```elixir
  editor = ExEditor.Editor.new(content: "hello")
  ```

- **Plugin validation is now enforced** - `new/1` raises `ArgumentError` if a plugin doesn't implement the `on_event/3` callback. Previously, invalid plugins were silently ignored.

### New Features

- **Undo to initial content** - Initial content is now pushed to history on editor creation, enabling undo back to the original content after changes.

- **CI/CD Pipeline** - Added comprehensive GitHub Actions workflows:
  - Matrix testing across Elixir 1.15-1.20 and OTP 26-29
  - Automated Hex.pm publishing on version tags
  - Fly.io deployment on main branch pushes
  - Version validation ensuring tag version matches `mix.exs`
  - CHANGELOG verification for releases

### Bug Fixes

- **Plugin notifications** - `undo/1` and `redo/1` now correctly pass `{old_content, new_content}` to plugins (previously passed `nil` for old content)
- **Plugin error handling** - Intermediate plugin state is now preserved when a plugin errors during `:handle_change` chain
- **Removed debug code** - Cleaned up `dbg()` call left in demo production code
- **Demo fixes** - Fixed deprecated Backpex configuration and test selectors

### Improvements

- Cleaner plugin system with `@impl true` annotations in all test plugins
- Better error messages for plugin validation failures
- Comprehensive test coverage for edge cases (undo/redo with plugins, max_size boundaries)

### Live Demo

Check out the live demo at **https://ex-editor.fly.dev**

---

**Full Changelog**: https://github.com/thanos/ex_editor/compare/v0.1.0...v0.2.0