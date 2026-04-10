defmodule ExEditor.HighlightedLinesCoverageTest do
  @moduledoc """
  Additional tests for HighlightedLines to increase coverage.
  Tests edge cases and variations in line wrapping.
  """
  use ExUnit.Case, async: true

  alias ExEditor.HighlightedLines

  describe "wrap_lines edge cases" do
    test "wrap_lines with multiple consecutive newlines" do
      result = HighlightedLines.wrap_lines("line1\n\nline3")
      assert result =~ ~s(<div class="ex-editor-line">line1</div>)
      assert result =~ ~s(<div class="ex-editor-line"></div>)
      assert result =~ ~s(<div class="ex-editor-line">line3</div>)
    end

    test "wrap_lines with trailing newline" do
      result = HighlightedLines.wrap_lines("line1\n")
      assert result =~ ~s(<div class="ex-editor-line">line1</div>)
      assert result =~ ~s(<div class="ex-editor-line"></div>)
    end

    test "wrap_lines with leading newline" do
      result = HighlightedLines.wrap_lines("\nline2")
      assert result =~ ~s(<div class="ex-editor-line"></div>)
      assert result =~ ~s(<div class="ex-editor-line">line2</div>)
    end

    test "wrap_lines preserves HTML formatting" do
      html = ~s(<span class="hl-keyword">def</span> hello)
      result = HighlightedLines.wrap_lines(html)
      assert String.contains?(result, "hl-keyword")
      assert String.contains?(result, "def")
    end

    test "wrap_lines with very long lines" do
      long_line = String.duplicate("a", 1000)
      result = HighlightedLines.wrap_lines(long_line)
      assert String.contains?(result, "aaaaaaaa")
      assert String.contains?(result, "ex-editor-line")
    end
  end

  describe "wrap_lines_with_empties edge cases" do
    test "wrap_lines_with_empties single empty line" do
      result = HighlightedLines.wrap_lines_with_empties("")
      assert result =~ ~s(<div class="ex-editor-line">&nbsp;</div>)
    end

    test "wrap_lines_with_empties multiple empty lines" do
      result = HighlightedLines.wrap_lines_with_empties("\n\n")
      # Should have 3 lines: empty, empty, empty
      empty_count = result |> String.split("&nbsp;") |> length()
      assert empty_count >= 3
    end

    test "wrap_lines_with_empties mixed content" do
      result = HighlightedLines.wrap_lines_with_empties("line1\n\nline3")
      assert result =~ "line1"
      assert result =~ "&nbsp;"
      assert result =~ "line3"
    end

    test "wrap_lines_with_empties preserves non-empty lines" do
      html = ~s(<span>code</span>\n\n<span>more</span>)
      result = HighlightedLines.wrap_lines_with_empties(html)
      assert String.contains?(result, "code")
      assert String.contains?(result, "more")
      assert String.contains?(result, "&nbsp;")
    end
  end

  describe "count_lines edge cases" do
    test "count_lines empty string" do
      assert HighlightedLines.count_lines("") == 1
    end

    test "count_lines single line" do
      assert HighlightedLines.count_lines("single line") == 1
    end

    test "count_lines multiple lines" do
      assert HighlightedLines.count_lines("line1\nline2\nline3") == 3
    end

    test "count_lines with trailing newline" do
      assert HighlightedLines.count_lines("line1\n") == 2
    end

    test "count_lines with leading newline" do
      assert HighlightedLines.count_lines("\nline2") == 2
    end

    test "count_lines with multiple consecutive newlines" do
      assert HighlightedLines.count_lines("a\n\n\nb") == 4
    end

    test "count_lines with only newlines" do
      assert HighlightedLines.count_lines("\n\n") == 3
    end

    test "count_lines with HTML content" do
      html = ~s(<span class="hl">code</span>\n<span class="hl">more</span>)
      assert HighlightedLines.count_lines(html) == 2
    end
  end

  describe "wrap_lines roundtrip consistency" do
    test "wrap_lines output maintains line count" do
      content = "line1\nline2\nline3"
      wrapped = HighlightedLines.wrap_lines(content)
      count = HighlightedLines.count_lines(content)

      # Should have exactly the right number of lines
      line_divs = wrapped |> String.split(~s(<div class="ex-editor-line">)) |> length()
      assert line_divs >= count
    end

    test "wrap_lines_with_empties preserves semantics" do
      content = "a\n\nb"
      wrapped = HighlightedLines.wrap_lines_with_empties(content)

      # All lines should be wrapped including empties (with nbsp)
      assert String.contains?(wrapped, "a")
      assert String.contains?(wrapped, "&nbsp;")
      assert String.contains?(wrapped, "b")
    end
  end
end
