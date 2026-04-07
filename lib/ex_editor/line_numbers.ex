defmodule ExEditor.LineNumbers do
  @moduledoc """
  Renders line numbers for code editor display.

  Generates HTML for line numbers with VS Code-inspired styling.
  Works in conjunction with syntax-highlighted content.

  ## Example

      ExEditor.LineNumbers.render(5)
      # => ~s(<div class="ex-editor-line-numbers">1\\n2\\n3\\n4\\n5</div>)

      doc = ExEditor.Document.from_text("line1\\nline2\\nline3")
      ExEditor.LineNumbers.render_for_document(doc)
      # => ~s(<div class="ex-editor-line-numbers">1\\n2\\n3</div>)
  """

  alias ExEditor.Document

  @doc """
  Renders line numbers for a given count.

  Returns HTML string with line numbers separated by newlines,
  wrapped in a div with the `ex-editor-line-numbers` class.

  ## Parameters

    - `count` - Number of lines to render (must be >= 1)

  ## Examples

      iex> ExEditor.LineNumbers.render(3)
      "<div class=\\"ex-editor-line-numbers\\">1\\n2\\n3</div>"

      iex> ExEditor.LineNumbers.render(1)
      "<div class=\\"ex-editor-line-numbers\\">1</div>"

      iex> ExEditor.LineNumbers.render(0)
      "<div class=\\"ex-editor-line-numbers\\">1</div>"
  """
  @spec render(non_neg_integer()) :: String.t()
  def render(count) when count < 1 do
    render(1)
  end

  def render(count) when is_integer(count) and count >= 1 do
    numbers =
      1..count
      |> Enum.map_join("\n", &Integer.to_string/1)

    ~s(<div class="ex-editor-line-numbers">#{numbers}</div>)
  end

  @doc """
  Renders line numbers for a document.

  Uses the document's line count to generate appropriate line numbers.

  ## Examples

      iex> doc = ExEditor.Document.from_text("hello\\nworld")
      iex> ExEditor.LineNumbers.render_for_document(doc)
      "<div class=\\"ex-editor-line-numbers\\">1\\n2</div>"

      iex> doc = ExEditor.Document.new()
      iex> ExEditor.LineNumbers.render_for_document(doc)
      "<div class=\\"ex-editor-line-numbers\\">1</div>"
  """
  @spec render_for_document(Document.t()) :: String.t()
  def render_for_document(%Document{} = doc) do
    doc
    |> Document.line_count()
    |> render()
  end

  @doc """
  Renders line numbers with a custom starting line number.

  Useful for displaying portions of a file (e.g., showing lines 50-60).

  ## Parameters

    - `count` - Number of lines to render
    - `start` - Starting line number (defaults to 1)

  ## Examples

      iex> ExEditor.LineNumbers.render_with_start(3, 10)
      "<div class=\\"ex-editor-line-numbers\\">10\\n11\\n12</div>"

      iex> ExEditor.LineNumbers.render_with_start(2, 1)
      "<div class=\\"ex-editor-line-numbers\\">1\\n2</div>"
  """
  @spec render_with_start(non_neg_integer(), pos_integer()) :: String.t()
  def render_with_start(count, start)
      when is_integer(count) and is_integer(start) and start >= 1 do
    actual_count = if count < 1, do: 1, else: count

    numbers =
      start..(start + actual_count - 1)
      |> Enum.map_join("\n", &Integer.to_string/1)

    ~s(<div class="ex-editor-line-numbers">#{numbers}</div>)
  end
end
