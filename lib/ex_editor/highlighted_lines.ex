defmodule ExEditor.HighlightedLines do
  @moduledoc """
  Utilities for processing syntax-highlighted content into line-based format.

  Takes highlighted HTML output and wraps it for proper alignment with line numbers
  in the editor's double-buffer rendering system.

  ## Example

      iex> html = ~s(<span class="hl-keyword">def</span> hello\\n<span class="hl-keyword">end</span>)
      iex> ExEditor.HighlightedLines.wrap_lines(html)
      ~s(<div class="ex-editor-line"><span class="hl-keyword">def</span> hello</div>\\n<div class="ex-editor-line"><span class="hl-keyword">end</span></div>)
  """

  @doc """
  Wraps each line of highlighted content in a div for line-by-line rendering.

  This ensures each line of code aligns perfectly with its corresponding line number
  when rendered in the double-buffer editor view.

  ## Parameters

    - `highlighted_html` - HTML string from a highlighter (may contain newlines)

  ## Returns

  HTML string with each line wrapped in `<div class="ex-editor-line">...</div>`

  ## Examples

      iex> ExEditor.HighlightedLines.wrap_lines("line1\\nline2")
      "<div class=\\"ex-editor-line\\">line1</div>\\n<div class=\\"ex-editor-line\\">line2</div>"

      iex> ExEditor.HighlightedLines.wrap_lines("single line")
      "<div class=\\"ex-editor-line\\">single line</div>"

      iex> ExEditor.HighlightedLines.wrap_lines("")
      "<div class=\\"ex-editor-line\\"></div>"
  """
  @spec wrap_lines(String.t()) :: String.t()
  def wrap_lines(highlighted_html) when is_binary(highlighted_html) do
    highlighted_html
    |> String.split("\n")
    |> Enum.map(&wrap_line/1)
    |> Enum.join("\n")
  end

  defp wrap_line(content) do
    ~s(<div class="ex-editor-line">#{content}</div>)
  end

  @doc """
  Wraps highlighted content with proper escaping for empty lines.

  Ensures empty lines are rendered with a non-breaking space or zero-width space
  to maintain proper line height in the editor.

  ## Examples

      iex> ExEditor.HighlightedLines.wrap_lines_with_empties("line1\\n\\nline3")
      "<div class=\\"ex-editor-line\\">line1</div>\\n<div class=\\"ex-editor-line\\">&nbsp;</div>\\n<div class=\\"ex-editor-line\\">line3</div>"
  """
  @spec wrap_lines_with_empties(String.t()) :: String.t()
  def wrap_lines_with_empties(highlighted_html) when is_binary(highlighted_html) do
    highlighted_html
    |> String.split("\n")
    |> Enum.map(&wrap_line_with_empty/1)
    |> Enum.join("\n")
  end

  defp wrap_line_with_empty(""), do: ~s(<div class="ex-editor-line">&nbsp;</div>)
  defp wrap_line_with_empty(content), do: wrap_line(content)

  @doc """
  Counts the number of lines in highlighted HTML content.

  Useful for verifying line count matches before rendering.

  ## Examples

      iex> ExEditor.HighlightedLines.count_lines("line1\\nline2\\nline3")
      3

      iex> ExEditor.HighlightedLines.count_lines("single")
      1

      iex> ExEditor.HighlightedLines.count_lines("")
      1
  """
  @spec count_lines(String.t()) :: pos_integer()
  def count_lines(highlighted_html) when is_binary(highlighted_html) do
    case String.split(highlighted_html, "\n") do
      [] -> 1
      lines -> length(lines)
    end
  end
end
