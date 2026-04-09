defmodule ExEditorTest do
  use ExUnit.Case, async: true
  doctest ExEditor

  describe "ExEditor.new/0" do
    test "creates a new editor with default empty content" do
      editor = ExEditor.new()
      assert is_struct(editor, ExEditor.Editor)
      assert ExEditor.Editor.get_content(editor) == ""
    end
  end

  describe "ExEditor.new/1" do
    test "creates a new editor with content option" do
      editor = ExEditor.new(content: "Hello, World!")
      assert ExEditor.Editor.get_content(editor) == "Hello, World!"
    end

    test "creates a new editor with multiple options" do
      editor = ExEditor.new(content: "def hello, do: :world", plugins: [])
      assert ExEditor.Editor.get_content(editor) == "def hello, do: :world"
    end
  end

  describe "ExEditor.document_from_text/1" do
    test "creates a document from single line text" do
      doc = ExEditor.document_from_text("single line")
      assert ExEditor.Document.line_count(doc) == 1
      {:ok, line} = ExEditor.Document.get_line(doc, 1)
      assert line == "single line"
    end

    test "creates a document from multi-line text" do
      doc = ExEditor.document_from_text("line1\nline2\nline3")
      assert ExEditor.Document.line_count(doc) == 3
      {:ok, line} = ExEditor.Document.get_line(doc, 2)
      assert line == "line2"
    end

    test "handles text with trailing newline" do
      doc = ExEditor.document_from_text("line1\nline2\n")
      assert ExEditor.Document.line_count(doc) == 3
      {:ok, line} = ExEditor.Document.get_line(doc, 3)
      assert line == ""
    end

    test "handles empty text" do
      doc = ExEditor.document_from_text("")
      assert ExEditor.Document.line_count(doc) == 1
      {:ok, line} = ExEditor.Document.get_line(doc, 1)
      assert line == ""
    end
  end
end
