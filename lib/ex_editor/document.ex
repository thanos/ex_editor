defmodule ExEditor.Document do
  @moduledoc """
  Represents the document state in the editor.

  The document is the core data structure that holds lines of text
  and provides operations for manipulating them.

  Lines are 1-indexed (line 1 is the first line).
  """

  defstruct lines: [""], cursor: {0, 0}

  @type cursor :: {line :: non_neg_integer(), column :: non_neg_integer()}
  @type t :: %__MODULE__{
          lines: [String.t()],
          cursor: cursor()
        }

  @doc """
  Creates a new empty document.

  ## Examples

      iex> ExEditor.Document.new()
      %ExEditor.Document{lines: [""], cursor: {0, 0}}
  """
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc """
  Creates a document from text content.
  Handles \\n, \\r\\n, and \\r line endings.

  ## Examples

      iex> ExEditor.Document.from_text("hello\\nworld")
      %ExEditor.Document{lines: ["hello", "world"], cursor: {0, 0}}
  """
  @spec from_text(String.t()) :: t()
  def from_text(text) when is_binary(text) do
    # Normalize line endings to \n
    normalized = text |> String.replace("\r\n", "\n") |> String.replace("\r", "\n")
    lines = String.split(normalized, "\n")
    %__MODULE__{lines: lines, cursor: {0, 0}}
  end

  @doc """
  Converts the document back to plain text.

  ## Examples

      iex> doc = ExEditor.Document.from_text("hello\\nworld")
      iex> ExEditor.Document.to_text(doc)
      "hello\\nworld"
  """
  @spec to_text(t()) :: String.t()
  def to_text(%__MODULE__{lines: lines}) do
    Enum.join(lines, "\n")
  end

  @doc """
  Gets the total number of lines in the document.

  ## Examples

      iex> doc = ExEditor.Document.from_text("hello\\nworld\\n!")
      iex> ExEditor.Document.line_count(doc)
      3
  """
  @spec line_count(t()) :: non_neg_integer()
  def line_count(%__MODULE__{lines: lines}) do
    length(lines)
  end

  @doc """
  Gets a specific line from the document (1-indexed).
  Returns {:ok, line} if successful, {:error, :invalid_line} if line doesn't exist.

  ## Examples

      iex> doc = ExEditor.Document.from_text("hello\\nworld")
      iex> ExEditor.Document.get_line(doc, 1)
      {:ok, "hello"}

      iex> doc = ExEditor.Document.from_text("hello\\nworld")
      iex> ExEditor.Document.get_line(doc, 0)
      {:error, :invalid_line}
  """
  @spec get_line(t(), pos_integer()) :: {:ok, String.t()} | {:error, :invalid_line}
  def get_line(%__MODULE__{lines: lines}, line_number) when line_number > 0 do
    case Enum.at(lines, line_number - 1) do
      nil -> {:error, :invalid_line}
      line -> {:ok, line}
    end
  end

  def get_line(%__MODULE__{}, _line_number) do
    {:error, :invalid_line}
  end

  @doc """
  Inserts a new line at the specified position (1-indexed).
  Lines after the insertion point are shifted down.

  ## Examples

      iex> doc = ExEditor.Document.from_text("line1\\nline3")
      iex> {:ok, updated} = ExEditor.Document.insert_line(doc, 2, "line2")
      iex> updated.lines
      ["line1", "line2", "line3"]
  """
  @spec insert_line(t(), pos_integer(), String.t()) :: {:ok, t()} | {:error, :invalid_line}
  def insert_line(%__MODULE__{lines: lines} = doc, position, content)
      when is_integer(position) and position > 0 and is_binary(content) do
    max_valid = length(lines) + 1

    if position > max_valid do
      {:error, :invalid_line}
    else
      updated_lines = List.insert_at(lines, position - 1, content)
      {:ok, %{doc | lines: updated_lines}}
    end
  end

  def insert_line(%__MODULE__{}, _position, _content) do
    {:error, :invalid_line}
  end

  @doc """
  Deletes a line at the specified position (1-indexed).
  If deleting the only line, leaves an empty document with one empty line.

  ## Examples

      iex> doc = ExEditor.Document.from_text("line1\\nline2\\nline3")
      iex> {:ok, updated} = ExEditor.Document.delete_line(doc, 2)
      iex> updated.lines
      ["line1", "line3"]
  """
  @spec delete_line(t(), pos_integer()) :: {:ok, t()} | {:error, :invalid_line}
  def delete_line(%__MODULE__{lines: lines} = doc, position)
      when is_integer(position) and position > 0 do
    if position > length(lines) do
      {:error, :invalid_line}
    else
      updated_lines =
        case List.delete_at(lines, position - 1) do
          [] -> [""]
          result -> result
        end

      {:ok, %{doc | lines: updated_lines}}
    end
  end

  def delete_line(%__MODULE__{}, _position) do
    {:error, :invalid_line}
  end

  @doc """
  Replaces a line at the specified position (1-indexed) with new content.

  ## Examples

      iex> doc = ExEditor.Document.from_text("old1\\nline2\\nline3")
      iex> {:ok, updated} = ExEditor.Document.replace_line(doc, 1, "new1")
      iex> updated.lines
      ["new1", "line2", "line3"]
  """
  @spec replace_line(t(), pos_integer(), String.t()) :: {:ok, t()} | {:error, :invalid_line}
  def replace_line(%__MODULE__{lines: lines} = doc, position, content)
      when is_integer(position) and position > 0 and is_binary(content) do
    if position > length(lines) do
      {:error, :invalid_line}
    else
      updated_lines = List.replace_at(lines, position - 1, content)
      {:ok, %{doc | lines: updated_lines}}
    end
  end

  def replace_line(%__MODULE__{}, _position, _content) do
    {:error, :invalid_line}
  end
end
