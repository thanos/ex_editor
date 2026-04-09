# ExEditor v0.3.0: Production-Ready Phoenix LiveView Code Editor with Backpex Integration

## TL;DR

ExEditor v0.3.0 is now available - a headless code editor library for Phoenix LiveView with:
- **Incremental diffs** (4-6x smaller payloads)
- **Always-visible syntax highlighting** (~50ms latency)
- **Backpex admin integration** with form sync
- **285 tests** with 88.7%+ coverage
- **Live demo** at https://ex-editor.fly.dev

---

## What is ExEditor?

ExEditor is a headless code editor library for Phoenix LiveView applications. It provides a production-ready editor component with native browser caret, instant line numbers, and perfect scroll alignment.

- [Hex](https://hex.pm/packages/ex_editor)
- [GitHub](https://github.com/thanos/ex_editor)
- [Changelog](https://github.com/thanos/ex_editor/blob/main/CHANGELOG.md)


## Key Features

### Good Responsiveness
- **Highlighting**: Syntax highlighting stays visible
- **Instant Line Numbers**: Line count updates immediately via JavaScript (0ms latency)
- **Native Caret**: Uses browser's native cursor - no JS overlay, no disappearing cursor
- **Perfect Scroll Sync**: Textarea, highlight layer, and gutter stay perfectly aligned

### Efficient Content Sync
- **Incremental Diffs**: Send only `{from, to, text}` instead of full content
- **4-6x Smaller Payloads**: ~20 bytes per keystroke vs ~120 bytes before
- **50ms Debounce**: Batches rapid keystrokes for efficiency
- **Smart Full-Sync**: Blur and paste events trigger full-content sync for safety

### Backpex Admin Integration (NEW!)
ExEditor now integrates seamlessly with Backpex:
- Custom field implementation for admin panels
- Syntax-highlighted code editing in forms
- Readonly display with line numbers on show pages
- Automatic form synchronization
- Complete guide with working examples

### Production-Ready Quality
- **285 tests** (12 doctests + 273 unit tests)
- **88.7%+ code coverage**
- Full LiveComponent integration tests
- Comprehensive documentation

## Performance Comparison
| Metric | Before | After |
|--------|--------|-------|
| Payload per keystroke | ~120 bytes | ~20 bytes |
| Highlighting latency | 2000+ ms | ~50 ms |
| Line number latency | 300+ ms | 0 ms |
| Network efficiency | Full content | Only diffs |

## Quick Start

### Installation

```elixir
{:ex_editor, "~> 0.3.0"}
```

### Usage

```elixir
<ExEditorWeb.LiveEditor.live_editor
  id="code-editor"
  content={@code}
  language={:elixir}
  on_change="code_changed"
/>
```

### Backpex Integration

```elixir
def fields do
  [
    code: %{
      module: MyAppWeb.Admin.Fields.CodeEditor,
      label: "Code"
    }
  ]
end
```

## Demo & Documentation

- **Live Demo**: https://ex-editor.fly.dev
- **GitHub**: https://github.com/thanos/ex_editor
- **Hex Package**: https://hex.pm/packages/ex_editor
- **API Docs**: https://hexdocs.pm/ex_editor
- **Backpex Integration Guide**: https://github.com/thanos/ex_editor/blob/main/guides/BACKPEX_INTEGRATION.md

## What's New in v0.3.0

**Headline Features**:
- Complete LiveView component with production-ready status
- Incremental diff synchronization for massive performance gains
- Backpex admin panel integration with full documentation
- Native browser caret for immediate visual feedback
- JS-managed line numbers (no server round-trip)
- Comprehensive test suite

**Bug Fixes**:
- Fixed cursor alignment issues
- Fixed line numbers lagging behind typing
- Fixed heredoc string line count preservation
- Fixed multi-line string HTML malformation

## Why This Matters

1. **Better UX**: Users see syntax highlighting at all times, not a 2-second gap
2. **Lower Costs**: 4-6x smaller payloads mean less bandwidth and server CPU
3. **Admin Integration**: Backpex users can now embed a full-featured editor in their admin panels
4. **Production Ready**: High test coverage and comprehensive documentation

## Architecture Highlights

**Double-Buffer Rendering**: Invisible textarea (captures input) + visible highlight layer (displays code)

**Incremental Sync**: Send only changed regions, not entire content

**JS-Managed UI**: JavaScript handles cursor, scroll sync, line numbers - no server round-trip

**Plugin System**: Extend functionality with behavior-based plugins

## Backwards Compatible

v0.3.0 is fully backward compatible with v0.2.0. No breaking changes.

## Next Steps

Try the live demo at https://ex-editor.fly.dev and check out the Backpex integration if you're using it in your admin panels!

Questions? Check the docs or open an issue on GitHub.

---

*ExEditor is open source and welcomes contributions. Special thanks to the Elixir and Phoenix communities for the amazing ecosystem!*
