defmodule ExEditor.HighlightedLinesTest do
  use ExUnit.Case, async: true

  alias ExEditor.HighlightedLines

  describe "wrap_lines/1" do
    test "wraps single line" do
      result = HighlightedLines.wrap_lines("single line")

      assert result == ~s(<div class="ex-editor-line">single line</div>)
    end

    test "wraps multiple lines" do
      result = HighlightedLines.wrap_lines("line1\nline2\nline3")

      assert result ==
               ~s(<div class="ex-editor-line">line1</div>\n<div class="ex-editor-line">line2</div>\n<div class="ex-editor-line">line3</div>)
    end

    test "wraps empty string" do
      result = HighlightedLines.wrap_lines("")

      assert result == ~s(<div class="ex-editor-line"></div>)
    end

    test "preserves highlighted HTML within lines" do
      result = HighlightedLines.wrap_lines(~s(<span class="hl-keyword">def</span> hello))

      assert result ==
               ~s(<div class="ex-editor-line"><span class="hl-keyword">def</span> hello</div>)
    end

    test "wraps lines with highlighted content" do
      html = ~s(<span class="hl-keyword">def</span> hello\n<span class="hl-keyword">end</span>)
      result = HighlightedLines.wrap_lines(html)

      assert result ==
               ~s(<div class="ex-editor-line"><span class="hl-keyword">def</span> hello</div>\n<div class="ex-editor-line"><span class="hl-keyword">end</span></div>)
    end
  end

  describe "wrap_lines_with_empties/1" do
    test "wraps lines with non-breaking space for empty lines" do
      result = HighlightedLines.wrap_lines_with_empties("line1\n\nline3")

      assert result ==
               ~s(<div class="ex-editor-line">line1</div>\n<div class="ex-editor-line">&nbsp;</div>\n<div class="ex-editor-line">line3</div>)
    end

    test "wraps single line normally" do
      result = HighlightedLines.wrap_lines_with_empties("single")

      assert result == ~s(<div class="ex-editor-line">single</div>)
    end

    test "wraps empty string as non-breaking space" do
      result = HighlightedLines.wrap_lines_with_empties("")

      assert result == ~s(<div class="ex-editor-line">&nbsp;</div>)
    end

    test "handles multiple consecutive empty lines" do
      result = HighlightedLines.wrap_lines_with_empties("line1\n\n\nline4")

      assert result ==
               ~s(<div class="ex-editor-line">line1</div>\n<div class="ex-editor-line">&nbsp;</div>\n<div class="ex-editor-line">&nbsp;</div>\n<div class="ex-editor-line">line4</div>)
    end
  end

  describe "count_lines/1" do
    test "counts single line" do
      assert HighlightedLines.count_lines("single") == 1
    end

    test "counts multiple lines" do
      assert HighlightedLines.count_lines("line1\nline2\nline3") == 3
    end

    test "counts empty string as one line" do
      assert HighlightedLines.count_lines("") == 1
    end

    test "counts lines with trailing newline" do
      assert HighlightedLines.count_lines("line1\nline2\n") == 3
    end
  end
end
