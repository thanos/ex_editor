defmodule ExEditorWeb.LiveEditorTest do
  use ExUnit.Case, async: true

  alias ExEditor.Document
  alias ExEditor.Editor
  alias ExEditor.HighlightedLines
  alias ExEditor.Highlighters.Elixir, as: ElixirHighlighter
  alias ExEditor.Highlighters.JSON, as: JSONHighlighter
  alias ExEditor.LineNumbers
  alias ExEditorWeb.LiveEditor

  describe "module structure" do
    test "LiveEditor module exists" do
      assert Code.ensure_loaded?(LiveEditor)
    end

    test "LiveEditor has LiveComponent callbacks" do
      functions = LiveEditor.__info__(:functions)

      assert Keyword.has_key?(functions, :handle_event)
      assert Keyword.has_key?(functions, :mount)
      assert Keyword.has_key?(functions, :update)
      assert Keyword.has_key?(functions, :render)
      assert Keyword.has_key?(functions, :live_editor)
    end
  end

  describe "language mapping" do
    test "supports elixir language" do
      highlighted = ElixirHighlighter.highlight("def hello, do: :world")

      assert String.contains?(highlighted, "hl-keyword")
    end

    test "supports json language" do
      json = ~s({"name": "test"})
      highlighted = JSONHighlighter.highlight(json)

      assert String.contains?(highlighted, "hl-key")
    end
  end

  describe "editor initialization" do
    test "creates editor with content" do
      editor = Editor.new(content: "test content")
      assert Editor.get_content(editor) == "test content"
    end

    test "creates empty editor without content" do
      editor = Editor.new()
      assert Editor.get_content(editor) == ""
    end

    test "sets highlighter for elixir" do
      editor = Editor.new(content: "def test, do: :ok")
      editor = Editor.set_highlighter(editor, ExEditor.Highlighters.Elixir)

      highlighted = Editor.get_highlighted_content(editor)
      assert String.contains?(highlighted, "hl-keyword")
    end
  end

  describe "content update" do
    test "updates content via set_content" do
      editor = Editor.new(content: "initial")
      {:ok, editor} = Editor.set_content(editor, "updated")

      assert Editor.get_content(editor) == "updated"
    end

    test "updates highlighted content after change" do
      editor = Editor.new(content: "def")
      editor = Editor.set_highlighter(editor, ExEditor.Highlighters.Elixir)

      highlighted_before = Editor.get_highlighted_content(editor)

      {:ok, editor} = Editor.set_content(editor, "defmodule Test do\nend")
      highlighted_after = Editor.get_highlighted_content(editor)

      assert highlighted_before != highlighted_after
      assert String.contains?(highlighted_after, "hl-keyword")
    end
  end

  describe "highlighting integration" do
    test "wrapped highlighted content has line divs" do
      html = "<span>line1</span>\n<span>line2</span>"
      wrapped = HighlightedLines.wrap_lines(html)

      assert String.contains?(wrapped, ~s(<div class="ex-editor-line">))
      assert String.contains?(wrapped, "line1")
      assert String.contains?(wrapped, "line2")
    end

    test "line numbers match document lines" do
      doc = Document.from_text("line1\nline2\nline3")
      line_numbers = LineNumbers.render_for_document(doc)

      assert String.contains?(line_numbers, "1\n2\n3")
    end
  end
end
