defmodule ExEditor.LineNumbersTest do
  use ExUnit.Case, async: true

  alias ExEditor.LineNumbers
  alias ExEditor.Document

  describe "render/1" do
    test "renders line numbers for given count" do
      result = LineNumbers.render(5)

      assert result == ~s(<div class="ex-editor-line-numbers">1\n2\n3\n4\n5</div>)
    end

    test "renders single line number for count of 1" do
      result = LineNumbers.render(1)

      assert result == ~s(<div class="ex-editor-line-numbers">1</div>)
    end

    test "renders single line number for count of 0" do
      result = LineNumbers.render(0)

      assert result == ~s(<div class="ex-editor-line-numbers">1</div>)
    end

    test "renders single line number for negative count" do
      result = LineNumbers.render(-5)

      assert result == ~s(<div class="ex-editor-line-numbers">1</div>)
    end

    test "renders large number of lines" do
      result = LineNumbers.render(100)

      assert String.contains?(result, "1\n2\n3")
      assert String.contains?(result, "99\n100")
    end
  end

  describe "render_for_document/1" do
    test "renders line numbers for document with multiple lines" do
      doc = Document.from_text("line1\nline2\nline3")
      result = LineNumbers.render_for_document(doc)

      assert result == ~s(<div class="ex-editor-line-numbers">1\n2\n3</div>)
    end

    test "renders single line for empty document" do
      doc = Document.new()
      result = LineNumbers.render_for_document(doc)

      assert result == ~s(<div class="ex-editor-line-numbers">1</div>)
    end

    test "renders line numbers for single line document" do
      doc = Document.from_text("single line")
      result = LineNumbers.render_for_document(doc)

      assert result == ~s(<div class="ex-editor-line-numbers">1</div>)
    end

    test "renders correct count for document with many lines" do
      text = Enum.join(1..50, "\n")
      doc = Document.from_text(text)
      result = LineNumbers.render_for_document(doc)

      assert String.contains?(result, "1\n2\n3")
      assert String.contains?(result, "49\n50")
    end
  end

  describe "render_with_start/2" do
    test "renders line numbers starting from custom start" do
      result = LineNumbers.render_with_start(3, 10)

      assert result == ~s(<div class="ex-editor-line-numbers">10\n11\n12</div>)
    end

    test "renders from start 1 by default" do
      result = LineNumbers.render_with_start(5, 1)

      assert result == ~s(<div class="ex-editor-line-numbers">1\n2\n3\n4\n5</div>)
    end

    test "handles count of 0 with custom start" do
      result = LineNumbers.render_with_start(0, 50)

      assert result == ~s(<div class="ex-editor-line-numbers">50</div>)
    end

    test "handles negative count with custom start" do
      result = LineNumbers.render_with_start(-1, 100)

      assert result == ~s(<div class="ex-editor-line-numbers">100</div>)
    end

    test "renders large range" do
      result = LineNumbers.render_with_start(5, 1000)

      assert result == ~s(<div class="ex-editor-line-numbers">1000\n1001\n1002\n1003\n1004</div>)
    end

    test "raises error for start less than 1" do
      assert_raise FunctionClauseError, fn ->
        LineNumbers.render_with_start(5, 0)
      end
    end
  end
end
