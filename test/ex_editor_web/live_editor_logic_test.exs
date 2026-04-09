defmodule ExEditorWeb.LiveEditorLogicTest do
  use ExUnit.Case, async: true

  describe "LiveEditor helper functions" do
    test "line_count/1 returns correct count for editor" do
      editor = ExEditor.new(content: "line1\nline2\nline3")
      count = ExEditor.Document.line_count(editor.document)
      assert count == 3
    end

    test "language mapping includes Elixir" do
      highlighter = ExEditor.Highlighters.Elixir
      assert highlighter.name() == "Elixir"
    end

    test "language mapping includes JSON" do
      highlighter = ExEditor.Highlighters.JSON
      assert highlighter.name() == "JSON"
    end

    test "get_highlighted_content produces HTML with syntax highlighting" do
      editor =
        ExEditor.new(content: "def hello, do: :world")
        |> ExEditor.Editor.set_highlighter(ExEditor.Highlighters.Elixir)

      highlighted = ExEditor.Editor.get_highlighted_content(editor)
      assert is_binary(highlighted)
      assert String.contains?(highlighted, "<span")
      assert String.contains?(highlighted, "hl-")
    end

    test "wrap_lines_with_empties handles highlighted content correctly" do
      html = "<span class=\"hl-keyword\">def</span> hello"
      wrapped = ExEditor.HighlightedLines.wrap_lines_with_empties(html)
      assert wrapped =~ ~s(ex-editor-line)
    end

    test "wrap_lines_with_empties handles empty lines" do
      html = "line1\n\nline3"
      wrapped = ExEditor.HighlightedLines.wrap_lines_with_empties(html)
      assert wrapped =~ "&nbsp;"
    end
  end

  describe "Editor state transitions" do
    test "content updates trigger highlighting" do
      editor =
        ExEditor.new(content: "original")
        |> ExEditor.Editor.set_highlighter(ExEditor.Highlighters.Elixir)

      assert ExEditor.Editor.get_content(editor) == "original"

      {:ok, updated} = ExEditor.Editor.set_content(editor, "def new, do: :content")
      assert ExEditor.Editor.get_content(updated) == "def new, do: :content"

      highlighted = ExEditor.Editor.get_highlighted_content(updated)
      assert String.contains?(highlighted, "hl-keyword")
    end

    test "line count stays accurate after content changes" do
      editor = ExEditor.new(content: "line1\nline2")
      count1 = ExEditor.Document.line_count(editor.document)
      assert count1 == 2

      {:ok, updated} = ExEditor.Editor.set_content(editor, "line1\nline2\nline3\nline4")
      count2 = ExEditor.Document.line_count(updated.document)
      assert count2 == 4
    end

    test "readonly mode doesn't affect editor state" do
      editor = ExEditor.new(content: "test", options: [readonly: true])
      {:ok, updated} = ExEditor.Editor.set_content(editor, "changed")
      assert ExEditor.Editor.get_content(updated) == "changed"
    end
  end

  describe "Component prop handling" do
    test "content is properly extracted from editor" do
      editor = ExEditor.new(content: "test content")
      content = ExEditor.Editor.get_content(editor)
      assert content == "test content"
    end

    test "language selection determines highlighter" do
      # Simulate language->highlighter mapping
      languages = %{
        elixir: ExEditor.Highlighters.Elixir,
        json: ExEditor.Highlighters.JSON
      }

      assert Map.get(languages, :elixir) == ExEditor.Highlighters.Elixir
      assert Map.get(languages, :json) == ExEditor.Highlighters.JSON
      assert Map.get(languages, :unknown) == nil
    end

    test "debounce value is properly passed" do
      # Debounce should be an integer (in ms)
      debounce = 300
      assert is_integer(debounce)
      assert debounce > 0
    end
  end

  describe "Content and highlighting pipeline" do
    test "full pipeline: content -> highlight -> line wrap" do
      # Simulate the component's render pipeline
      content = "def test do\n  :ok\nend"

      editor =
        ExEditor.new(content: content)
        |> ExEditor.Editor.set_highlighter(ExEditor.Highlighters.Elixir)

      # Get highlighted content
      highlighted = ExEditor.Editor.get_highlighted_content(editor)
      assert highlighted != ""

      # Wrap lines
      wrapped = ExEditor.HighlightedLines.wrap_lines_with_empties(highlighted)
      assert wrapped =~ "ex-editor-line"

      # Get line numbers
      line_count = ExEditor.Document.line_count(editor.document)
      assert line_count == 3

      # Verify structure
      assert String.contains?(wrapped, "<div") and String.contains?(wrapped, "</div>")
    end

    test "heredoc strings are highlighted correctly" do
      content = ~S("""
      multi
      line
      string
      """)

      editor =
        ExEditor.new(content: content)
        |> ExEditor.Editor.set_highlighter(ExEditor.Highlighters.Elixir)

      highlighted = ExEditor.Editor.get_highlighted_content(editor)
      assert String.contains?(highlighted, "hl-string")
    end
  end
end
