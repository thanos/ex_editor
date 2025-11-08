defmodule ExEditor.Document do
  @moduledoc """
  Represents the document state in the editor.

  The document is the core data structure that holds lines of text
  and provides operations for manipulating them.
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

  ## Examples

      iex> ExEditor.Document.from_text("hello\\nworld")
      %ExEditor.Document{lines: ["hello", "world"], cursor: {0, 0}}
  """
  @spec from_text(String.t()) :: t()
  def from_text(text) when is_binary(text) do
    lines = String.split(text, "\n")
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
  Gets a specific line from the document (0-indexed).
  Returns nil if line doesn't exist.

  ## Examples

      iex> doc = ExEditor.Document.from_text("hello\\nworld")
      iex> ExEditor.Document.get_line(doc, 1)
      "world"
  """
  @spec get_line(t(), non_neg_integer()) :: String.t() | nil
  def get_line(%__MODULE__{lines: lines}, line_number) do
    Enum.at(lines, line_number)
  end
end
