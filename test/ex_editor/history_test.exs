defmodule ExEditor.HistoryTest do
  use ExUnit.Case

  alias ExEditor.Document
  alias ExEditor.History

  describe "new/1" do
    test "creates history with default max_size" do
      history = History.new()
      assert history.max_size == 100
      assert history.entries == []
      assert history.cursor == 0
    end

    test "creates history with custom max_size" do
      history = History.new(50)
      assert history.max_size == 50
    end
  end

  describe "push/2" do
    test "pushes document to empty history" do
      doc = Document.from_text("first")
      history = History.push(History.new(), doc)

      assert length(history.entries) == 1
      assert history.cursor == 1
    end

    test "pushes multiple documents" do
      history =
        History.new()
        |> History.push(Document.from_text("first"))
        |> History.push(Document.from_text("second"))
        |> History.push(Document.from_text("third"))

      assert length(history.entries) == 3
      assert history.cursor == 3
    end

    test "clears redo stack on push" do
      history =
        History.new()
        |> History.push(Document.from_text("first"))
        |> History.push(Document.from_text("second"))

      {:ok, _, history} = History.undo(history)

      assert History.can_redo?(history)

      history = History.push(history, Document.from_text("third"))

      refute History.can_redo?(history)
      assert length(history.entries) == 2
    end

    test "enforces max_size by dropping oldest entries" do
      history = History.new(3)

      history =
        history
        |> History.push(Document.from_text("1"))
        |> History.push(Document.from_text("2"))
        |> History.push(Document.from_text("3"))
        |> History.push(Document.from_text("4"))

      assert length(history.entries) == 3
      assert history.cursor == 3

      # First entry should be dropped
      assert Document.to_text(hd(history.entries)) == "2"
    end
  end

  describe "undo/1" do
    test "returns error when no history" do
      assert {:error, :no_history} = History.undo(History.new())
    end

    test "undoes to the only entry" do
      history = History.push(History.new(), Document.from_text("only"))
      assert {:error, :no_history} = History.undo(history)
    end

    test "undoes to previous entry" do
      history =
        History.new()
        |> History.push(Document.from_text("state1"))
        |> History.push(Document.from_text("state2"))
        |> History.push(Document.from_text("state3"))

      {:ok, doc, history} = History.undo(history)

      assert Document.to_text(doc) == "state2"
      assert history.cursor == 2
    end

    test "can undo multiple times" do
      history =
        History.new()
        |> History.push(Document.from_text("1"))
        |> History.push(Document.from_text("2"))
        |> History.push(Document.from_text("3"))

      {:ok, doc1, history} = History.undo(history)
      assert Document.to_text(doc1) == "2"

      {:ok, doc2, history} = History.undo(history)
      assert Document.to_text(doc2) == "1"

      refute History.can_undo?(history)
    end
  end

  describe "redo/1" do
    test "returns error when no redo available" do
      assert {:error, :no_redo} = History.redo(History.new())
    end

    test "returns next document after undo" do
      history =
        History.new()
        |> History.push(Document.from_text("first"))
        |> History.push(Document.from_text("second"))
        |> History.push(Document.from_text("third"))

      {:ok, _, history} = History.undo(history)
      {:ok, doc, history} = History.redo(history)

      assert Document.to_text(doc) == "third"
      assert history.cursor == 3
    end

    test "returns error without prior undo" do
      history =
        History.new()
        |> History.push(Document.from_text("first"))

      assert {:error, :no_redo} = History.redo(history)
    end
  end

  describe "can_undo?/1" do
    test "returns false for empty history" do
      refute History.can_undo?(History.new())
    end

    test "returns false after single push" do
      history = History.push(History.new(), Document.from_text("test"))
      refute History.can_undo?(history)
    end

    test "returns true after multiple pushes" do
      history =
        History.new()
        |> History.push(Document.from_text("first"))
        |> History.push(Document.from_text("second"))

      assert History.can_undo?(history)
    end

    test "returns false after undoing all" do
      history =
        History.new()
        |> History.push(Document.from_text("first"))
        |> History.push(Document.from_text("second"))

      {:ok, _, history} = History.undo(history)

      refute History.can_undo?(history)
    end
  end

  describe "can_redo?/1" do
    test "returns false for empty history" do
      refute History.can_redo?(History.new())
    end

    test "returns true after undo" do
      history =
        History.new()
        |> History.push(Document.from_text("first"))
        |> History.push(Document.from_text("second"))

      {:ok, _, history} = History.undo(history)

      assert History.can_redo?(history)
    end

    test "returns false after redoing all" do
      history =
        History.new()
        |> History.push(Document.from_text("first"))
        |> History.push(Document.from_text("second"))

      {:ok, _, history} = History.undo(history)
      {:ok, _, history} = History.redo(history)

      refute History.can_redo?(history)
    end
  end

  describe "clear/1" do
    test "clears all history" do
      history =
        History.new()
        |> History.push(Document.from_text("first"))
        |> History.push(Document.from_text("second"))

      history = History.clear(history)

      assert history.entries == []
      assert history.cursor == 0
      refute History.can_undo?(history)
      refute History.can_redo?(history)
    end

    test "preserves max_size" do
      history = History.new(50)
      history = History.push(history, Document.from_text("test"))
      history = History.clear(history)

      assert history.max_size == 50
    end
  end
end
