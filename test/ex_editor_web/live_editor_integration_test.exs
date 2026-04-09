defmodule ExEditorWeb.LiveEditorIntegrationTest do
  use ExUnit.Case, async: true

  alias ExEditor.{Document, Editor, HighlightedLines, LineNumbers}

  describe "double-buffer rendering" do
    test "highlighted content matches document lines" do
      content = "line1\nline2\nline3"
      editor = Editor.new(content: content)

      highlighted = Editor.get_highlighted_content(editor)
      lines = HighlightedLines.count_lines(highlighted)

      assert lines == Document.line_count(editor.document)
    end

    test "line numbers match document" do
      content = "line1\nline2\nline3"
      doc = Document.from_text(content)

      line_numbers = LineNumbers.render_for_document(doc)

      assert line_numbers =~ "1"
      assert line_numbers =~ "2"
      assert line_numbers =~ "3"
    end

    test "wrapped highlighted content has correct line count" do
      content = "def hello, do: :world\ndef goodbye, do: :ok"
      editor = Editor.new(content: content)
      editor = Editor.set_highlighter(editor, ExEditor.Highlighters.Elixir)

      highlighted = Editor.get_highlighted_content(editor)
      wrapped = HighlightedLines.wrap_lines(highlighted)

      assert String.contains?(wrapped, ~s(<div class="ex-editor-line">))
      assert wrapped =~ "def"
    end
  end

  describe "syntax highlighting integration" do
    test "Elixir highlighter produces valid HTML" do
      content = "defmodule Test do\nend"
      editor = Editor.new(content: content)
      editor = Editor.set_highlighter(editor, ExEditor.Highlighters.Elixir)

      highlighted = Editor.get_highlighted_content(editor)

      assert highlighted =~ "hl-keyword"
      assert highlighted =~ "hl-module"
    end

    test "JSON highlighter produces valid HTML" do
      content = ~s({"key": "value"})
      editor = Editor.new(content: content)
      editor = Editor.set_highlighter(editor, ExEditor.Highlighters.JSON)

      highlighted = Editor.get_highlighted_content(editor)

      assert highlighted =~ "hl-key"
      assert highlighted =~ "hl-string"
    end

    test "no highlighter returns plain text" do
      content = "plain text"
      editor = Editor.new(content: content)

      highlighted = Editor.get_highlighted_content(editor)

      assert highlighted == content
    end
  end

  describe "content updates" do
    test "highlighting updates with content changes" do
      editor = Editor.new(content: "initial")
      editor = Editor.set_highlighter(editor, ExEditor.Highlighters.Elixir)

      highlighted_before = Editor.get_highlighted_content(editor)

      {:ok, editor} = Editor.set_content(editor, "defmodule NewContent do\nend")
      highlighted_after = Editor.get_highlighted_content(editor)

      assert highlighted_before != highlighted_after
      assert highlighted_after =~ "hl-keyword"
    end

    test "line numbers update with content changes" do
      editor = Editor.new(content: "line1")
      line_numbers_before = LineNumbers.render_for_document(editor.document)

      {:ok, editor} = Editor.set_content(editor, "line1\nline2\nline3")
      line_numbers_after = LineNumbers.render_for_document(editor.document)

      refute line_numbers_before =~ "3"
      assert line_numbers_after =~ "3"
    end
  end

  describe "edge cases" do
    test "empty content renders correctly" do
      editor = Editor.new(content: "")
      highlighted = Editor.get_highlighted_content(editor)
      line_numbers = LineNumbers.render_for_document(editor.document)

      assert highlighted == ""
      assert line_numbers =~ "1"
    end

    test "single line content renders correctly" do
      editor = Editor.new(content: "single line")
      highlighted = Editor.get_highlighted_content(editor)
      wrapped = HighlightedLines.wrap_lines(highlighted)

      assert wrapped =~ "single line"
      assert wrapped =~ ~s(<div class="ex-editor-line">)
    end

    test "very long line renders correctly" do
      long_line = String.duplicate("x", 1000)
      editor = Editor.new(content: long_line)

      highlighted = Editor.get_highlighted_content(editor)

      assert highlighted == long_line
    end

    test "large number of lines renders correctly" do
      lines = Enum.map_join(1..100, "\n", fn i -> "line #{i}" end)
      editor = Editor.new(content: lines)

      line_numbers = LineNumbers.render_for_document(editor.document)

      assert line_numbers =~ "1"
      assert line_numbers =~ "100"
    end

    test "empty lines in content" do
      content = "line1\n\nline3"
      editor = Editor.new(content: content)
      wrapped = HighlightedLines.wrap_lines_with_empties(Editor.get_highlighted_content(editor))

      assert wrapped =~ "&nbsp;"
    end
  end

  describe "undo/redo with highlighting" do
    test "undo restores previous highlighted state" do
      editor = Editor.new(content: "first")
      editor = Editor.set_highlighter(editor, ExEditor.Highlighters.Elixir)

      {:ok, editor} = Editor.set_content(editor, "defmodule Test do\nend")

      highlighted_after_change = Editor.get_highlighted_content(editor)

      {:ok, editor} = Editor.undo(editor)

      highlighted_after_undo = Editor.get_highlighted_content(editor)

      assert highlighted_after_change != highlighted_after_undo
      assert Editor.get_content(editor) == "first"
    end
  end
end
