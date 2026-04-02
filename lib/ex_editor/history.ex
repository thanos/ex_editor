defmodule ExEditor.History do
  @moduledoc """
  Manages undo/redo history for the editor.

  History stores document snapshots in a bounded list.
  The cursor is 1-indexed and points PAST the last entry.

       entries: [A, B, C]
       cursor: 3 (pointing past C, which represents the current state)

  This design matches how Editor uses history:
  - `push(new_doc)` is called AFTER changing content
  - cursor = length of entries after push
  - `undo()` returns `entries[cursor-1]` and decrements cursor

  ## Example workflow (Editor perspective)

      # User edits: "hello" → "hello world" → "hello world!"
      # entries=["hello", "hello world", "hello world!"], cursor=3
      
      {:ok, doc, history} = History.undo(history)  # returns "hello world"
      {:ok, doc, history} = History.redo(history)  # returns "hello world!"
  """

  alias ExEditor.Document

  defstruct entries: [], cursor: 0, max_size: 100

  @type t :: %__MODULE__{
          entries: [Document.t()],
          cursor: non_neg_integer(),
          max_size: pos_integer()
        }

  @doc """
  Creates a new empty history.

  ## Examples

      iex> history = ExEditor.History.new()
      iex> history.max_size
      100

      iex> history = ExEditor.History.new(50)
      iex> history.max_size
      50
  """
  @spec new(pos_integer()) :: t()
  def new(max_size \\ 100) do
    %__MODULE__{entries: [], cursor: 0, max_size: max_size}
  end

  @doc """
  Pushes a document snapshot to history. Clears redo stack.

  ## Examples

      iex> history = ExEditor.History.new()
      iex> doc = ExEditor.Document.from_text("hello")
      iex> history = ExEditor.History.push(history, doc)
      iex> ExEditor.History.can_undo?(history)
      true
  """
  @spec push(t(), Document.t()) :: t()
  def push(%__MODULE__{entries: entries, cursor: cursor, max_size: max_size}, document) do
    # Clear everything after cursor (redo stack)
    entries = Enum.take(entries, cursor)

    # Add new entry
    entries = entries ++ [document]

    # Enforce max size by dropping oldest entries
    entries =
      if length(entries) > max_size do
        Enum.drop(entries, length(entries) - max_size)
      else
        entries
      end

    %__MODULE__{entries: entries, cursor: length(entries), max_size: max_size}
  end

  @doc """
  Undoes the last change. Returns the previous document and updated history.

  ## Examples

      iex> history = ExEditor.History.new()
      iex> doc1 = ExEditor.Document.from_text("one")
      iex> doc2 = ExEditor.Document.from_text("two")
      iex> doc3 = ExEditor.Document.from_text("three")
      iex> history = ExEditor.History.push(history, doc1)
      iex> history = ExEditor.History.push(history, doc2)
      iex> history = ExEditor.History.push(history, doc3)
      iex> {:ok, doc, history} = ExEditor.History.undo(history)
      iex> ExEditor.Document.to_text(doc)
      "two"
  """
  @spec undo(t()) :: {:ok, Document.t(), t()} | {:error, :no_history}
  def undo(%__MODULE__{entries: entries, cursor: cursor} = history) when cursor >= 2 do
    document = Enum.at(entries, cursor - 2)
    {:ok, document, %{history | cursor: cursor - 1}}
  end

  def undo(%__MODULE__{}), do: {:error, :no_history}

  @doc """
  Redoes the last undone change. Returns the next document and updated history.

  ## Examples

      iex> history = ExEditor.History.new()
      iex> doc1 = ExEditor.Document.from_text("one")
      iex> doc2 = ExEditor.Document.from_text("two")
      iex> doc3 = ExEditor.Document.from_text("three")
      iex> history = ExEditor.History.push(history, doc1)
      iex> history = ExEditor.History.push(history, doc2)
      iex> history = ExEditor.History.push(history, doc3)
      iex> {:ok, _, history} = ExEditor.History.undo(history)
      iex> {:ok, doc, _} = ExEditor.History.redo(history)
      iex> ExEditor.Document.to_text(doc)
      "three"
  """
  @spec redo(t()) :: {:ok, Document.t(), t()} | {:error, :no_redo}
  def redo(%__MODULE__{entries: entries, cursor: cursor} = history)
      when cursor < length(entries) do
    new_cursor = cursor + 1
    document = Enum.at(entries, new_cursor - 1)
    {:ok, document, %{history | cursor: new_cursor}}
  end

  def redo(%__MODULE__{}), do: {:error, :no_redo}

  @doc """
  Checks if undo is available.

  ## Examples

      iex> history = ExEditor.History.new()
      iex> ExEditor.History.can_undo?(history)
      false

      iex> history = ExEditor.History.new()
      iex> history = ExEditor.History.push(history, ExEditor.Document.from_text("test"))
      iex> ExEditor.History.can_undo?(history)
      false

      iex> history = ExEditor.History.new()
      iex> history = ExEditor.History.push(history, ExEditor.Document.from_text("first"))
      iex> history = ExEditor.History.push(history, ExEditor.Document.from_text("second"))
      iex> ExEditor.History.can_undo?(history)
      true
  """
  @spec can_undo?(t()) :: boolean()
  def can_undo?(%__MODULE__{cursor: cursor}), do: cursor >= 2

  @doc """
  Checks if redo is available.

  ## Examples

      iex> history = ExEditor.History.new()
      iex> ExEditor.History.can_redo?(history)
      false
  """
  @spec can_redo?(t()) :: boolean()
  def can_redo?(%__MODULE__{entries: entries, cursor: cursor}), do: cursor < length(entries)

  @doc """
  Clears all history.

  ## Examples

      iex> history = ExEditor.History.new()
      iex> history = ExEditor.History.push(history, ExEditor.Document.from_text("test"))
      iex> history = ExEditor.History.clear(history)
      iex> ExEditor.History.can_undo?(history)
      false
  """
  @spec clear(t()) :: t()
  def clear(%__MODULE__{max_size: max_size}) do
    %__MODULE__{entries: [], cursor: 0, max_size: max_size}
  end
end
