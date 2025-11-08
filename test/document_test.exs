defmodule ExEditor.DocumentTest do
  use ExUnit.Case, async: true
  doctest ExEditor.Document

  alias ExEditor.Document

  describe "new/0" do
    test "creates an empty document with one blank line" do
      doc = Document.new()
      assert doc.lines == [""]
    end
  end

  describe "from_text/1" do
    test "creates document from empty string" do
      doc = Document.from_text("")
      assert doc.lines == [""]
    end

    test "creates document from single line" do
      doc = Document.from_text("hello world")
      assert doc.lines == ["hello world"]
    end

    test "creates document from multiple lines with \\n" do
      doc = Document.from_text("line1\nline2\nline3")
      assert doc.lines == ["line1", "line2", "line3"]
    end

    test "creates document from text with trailing newline" do
      doc = Document.from_text("line1\nline2\n")
      assert doc.lines == ["line1", "line2", ""]
    end

    test "handles mixed line endings (\\n and \\r\\n)" do
      doc = Document.from_text("line1\r\nline2\nline3")
      assert doc.lines == ["line1", "line2", "line3"]
    end

    test "handles only \\r\\n line endings" do
      doc = Document.from_text("line1\r\nline2\r\nline3")
      assert doc.lines == ["line1", "line2", "line3"]
    end

    test "preserves empty lines in the middle" do
      doc = Document.from_text("line1\n\nline3")
      assert doc.lines == ["line1", "", "line3"]
    end

    test "handles very long lines" do
      long_line = String.duplicate("a", 10_000)
      doc = Document.from_text(long_line)
      assert doc.lines == [long_line]
    end
  end

  describe "to_text/1" do
    test "converts empty document to empty string" do
      doc = Document.new()
      assert Document.to_text(doc) == ""
    end

    test "converts single line document" do
      doc = %Document{lines: ["hello world"]}
      assert Document.to_text(doc) == "hello world"
    end

    test "converts multi-line document with \\n separator" do
      doc = %Document{lines: ["line1", "line2", "line3"]}
      assert Document.to_text(doc) == "line1\nline2\nline3"
    end

    test "preserves empty lines" do
      doc = %Document{lines: ["line1", "", "line3"]}
      assert Document.to_text(doc) == "line1\n\nline3"
    end

    test "handles document with trailing empty line" do
      doc = %Document{lines: ["line1", "line2", ""]}
      assert Document.to_text(doc) == "line1\nline2\n"
    end
  end

  describe "get_line/2" do
    setup do
      doc = %Document{lines: ["line1", "line2", "line3"]}
      {:ok, doc: doc}
    end

    test "gets first line (1-indexed)", %{doc: doc} do
      assert Document.get_line(doc, 1) == {:ok, "line1"}
    end

    test "gets middle line", %{doc: doc} do
      assert Document.get_line(doc, 2) == {:ok, "line2"}
    end

    test "gets last line", %{doc: doc} do
      assert Document.get_line(doc, 3) == {:ok, "line3"}
    end

    test "returns error for line 0", %{doc: doc} do
      assert Document.get_line(doc, 0) == {:error, :invalid_line}
    end

    test "returns error for negative line", %{doc: doc} do
      assert Document.get_line(doc, -1) == {:error, :invalid_line}
    end

    test "returns error for line beyond document", %{doc: doc} do
      assert Document.get_line(doc, 4) == {:error, :invalid_line}
    end
  end

  describe "insert_line/3" do
    test "inserts line at beginning" do
      doc = %Document{lines: ["line2", "line3"]}
      {:ok, updated} = Document.insert_line(doc, 1, "line1")
      assert updated.lines == ["line1", "line2", "line3"]
    end

    test "inserts line in middle" do
      doc = %Document{lines: ["line1", "line3"]}
      {:ok, updated} = Document.insert_line(doc, 2, "line2")
      assert updated.lines == ["line1", "line2", "line3"]
    end

    test "inserts line at end" do
      doc = %Document{lines: ["line1", "line2"]}
      {:ok, updated} = Document.insert_line(doc, 3, "line3")
      assert updated.lines == ["line1", "line2", "line3"]
    end

    test "appends line after last line" do
      doc = %Document{lines: ["line1"]}
      {:ok, updated} = Document.insert_line(doc, 2, "line2")
      assert updated.lines == ["line1", "line2"]
    end

    test "returns error for invalid position 0" do
      doc = %Document{lines: ["line1"]}
      assert Document.insert_line(doc, 0, "new") == {:error, :invalid_line}
    end

    test "returns error for invalid negative position" do
      doc = %Document{lines: ["line1"]}
      assert Document.insert_line(doc, -1, "new") == {:error, :invalid_line}
    end

    test "returns error for position far beyond document" do
      doc = %Document{lines: ["line1"]}
      assert Document.insert_line(doc, 100, "new") == {:error, :invalid_line}
    end
  end

  describe "delete_line/2" do
    test "deletes first line" do
      doc = %Document{lines: ["line1", "line2", "line3"]}
      {:ok, updated} = Document.delete_line(doc, 1)
      assert updated.lines == ["line2", "line3"]
    end

    test "deletes middle line" do
      doc = %Document{lines: ["line1", "line2", "line3"]}
      {:ok, updated} = Document.delete_line(doc, 2)
      assert updated.lines == ["line1", "line3"]
    end

    test "deletes last line" do
      doc = %Document{lines: ["line1", "line2", "line3"]}
      {:ok, updated} = Document.delete_line(doc, 3)
      assert updated.lines == ["line1", "line2"]
    end

    test "deleting only line leaves empty document" do
      doc = %Document{lines: ["only line"]}
      {:ok, updated} = Document.delete_line(doc, 1)
      assert updated.lines == [""]
    end

    test "returns error for line 0" do
      doc = %Document{lines: ["line1"]}
      assert Document.delete_line(doc, 0) == {:error, :invalid_line}
    end

    test "returns error for negative line" do
      doc = %Document{lines: ["line1"]}
      assert Document.delete_line(doc, -1) == {:error, :invalid_line}
    end

    test "returns error for line beyond document" do
      doc = %Document{lines: ["line1"]}
      assert Document.delete_line(doc, 2) == {:error, :invalid_line}
    end
  end

  describe "replace_line/3" do
    test "replaces first line" do
      doc = %Document{lines: ["old1", "line2", "line3"]}
      {:ok, updated} = Document.replace_line(doc, 1, "new1")
      assert updated.lines == ["new1", "line2", "line3"]
    end

    test "replaces middle line" do
      doc = %Document{lines: ["line1", "old2", "line3"]}
      {:ok, updated} = Document.replace_line(doc, 2, "new2")
      assert updated.lines == ["line1", "new2", "line3"]
    end

    test "replaces last line" do
      doc = %Document{lines: ["line1", "line2", "old3"]}
      {:ok, updated} = Document.replace_line(doc, 3, "new3")
      assert updated.lines == ["line1", "line2", "new3"]
    end

    test "replaces with empty string" do
      doc = %Document{lines: ["line1", "line2"]}
      {:ok, updated} = Document.replace_line(doc, 1, "")
      assert updated.lines == ["", "line2"]
    end

    test "returns error for line 0" do
      doc = %Document{lines: ["line1"]}
      assert Document.replace_line(doc, 0, "new") == {:error, :invalid_line}
    end

    test "returns error for negative line" do
      doc = %Document{lines: ["line1"]}
      assert Document.replace_line(doc, -1, "new") == {:error, :invalid_line}
    end

    test "returns error for line beyond document" do
      doc = %Document{lines: ["line1"]}
      assert Document.replace_line(doc, 2, "new") == {:error, :invalid_line}
    end
  end

  describe "line_count/1" do
    test "returns 1 for empty document" do
      doc = Document.new()
      assert Document.line_count(doc) == 1
    end

    test "returns correct count for single line" do
      doc = %Document{lines: ["line1"]}
      assert Document.line_count(doc) == 1
    end

    test "returns correct count for multiple lines" do
      doc = %Document{lines: ["line1", "line2", "line3"]}
      assert Document.line_count(doc) == 3
    end

    test "counts empty lines" do
      doc = %Document{lines: ["line1", "", "line3"]}
      assert Document.line_count(doc) == 3
    end
  end

  describe "roundtrip conversions" do
    test "text -> document -> text preserves content" do
      original = "line1\nline2\nline3"
      doc = Document.from_text(original)
      result = Document.to_text(doc)
      assert result == original
    end

    test "roundtrip with empty lines" do
      original = "line1\n\nline3"
      doc = Document.from_text(original)
      result = Document.to_text(doc)
      assert result == original
    end

    test "roundtrip with trailing newline" do
      original = "line1\nline2\n"
      doc = Document.from_text(original)
      result = Document.to_text(doc)
      assert result == original
    end

    test "roundtrip with single line no newline" do
      original = "single line"
      doc = Document.from_text(original)
      result = Document.to_text(doc)
      assert result == original
    end
  end
end
