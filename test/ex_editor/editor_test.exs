defmodule ExEditor.EditorTest do
  use ExUnit.Case
  alias ExEditor.Document
  alias ExEditor.Editor

  describe "new/1" do
    test "creates a new editor with an empty document by default" do
      editor = Editor.new()
      assert %Editor{document: %Document{lines: [""]}} = editor
      assert editor.plugins == []
      assert editor.options == []
      assert editor.metadata == %{}
    end

    test "creates a new editor with provided content" do
      editor = Editor.new(content: "hello world")
      assert %Editor{} = editor
      assert ExEditor.Document.to_text(editor.document) == "hello world"
    end

    test "raises on invalid plugin" do
      assert_raise ArgumentError, ~r/must implement on_event\/3 callback/, fn ->
        Editor.new(plugins: [String])
      end
    end

    test "creates a new editor with provided plugins" do
      editor = Editor.new(plugins: [TestPlugins.MyPlugin])
      assert editor.plugins == [TestPlugins.MyPlugin]
    end
  end

  describe "set_content/2" do
    test "sets new content for the editor" do
      editor = Editor.new(content: "old content")
      {:ok, updated_editor} = Editor.set_content(editor, "new content")
      assert ExEditor.Document.to_text(updated_editor.document) == "new content"
    end

    test "returns error for invalid content" do
      editor = Editor.new()
      {:error, :invalid_content} = Editor.set_content(editor, nil)
    end

    test "notifies plugins of content change" do
      test_pid = self()

      Process.put(:test_pid, test_pid)

      editor = Editor.new(plugins: [TestPlugins.MockPlugin], content: "initial")
      {:ok, _updated_editor} = Editor.set_content(editor, "changed content")

      assert_receive {:plugin_event, :handle_change}
    end

    test "before_change event can reject changes" do
      editor = Editor.new(plugins: [TestPlugins.RejectPlugin])

      assert {:error, :forbidden_word} = Editor.set_content(editor, "forbidden content")
      assert {:ok, _} = Editor.set_content(editor, "allowed content")
    end

    test "plugins can modify editor via metadata" do
      editor = Editor.new(plugins: [TestPlugins.MetaPlugin])
      {:ok, editor} = Editor.set_content(editor, "hello")

      assert Editor.get_metadata(editor, :change_count) == 5
    end

    test "multiple plugins form middleware chain" do
      editor = Editor.new(plugins: [TestPlugins.CounterPlugin, TestPlugins.CounterPlugin])
      {:ok, editor} = Editor.set_content(editor, "test")

      assert Editor.get_metadata(editor, :count) == 2
    end

    test "handle_change errors are ignored after document change" do
      editor = Editor.new(plugins: [TestPlugins.ErrorOnHandleChangePlugin])
      {:ok, editor} = Editor.set_content(editor, "test")

      # Document should still be updated despite plugin error
      assert Editor.get_content(editor) == "test"
    end
  end

  describe "get_content/1" do
    test "returns the current content of the editor" do
      editor = Editor.new(content: "some text")
      assert Editor.get_content(editor) == "some text"
    end

    test "returns empty string for new editor" do
      editor = Editor.new()
      assert Editor.get_content(editor) == ""
    end
  end

  describe "put_metadata/3" do
    test "stores metadata in the editor" do
      editor = Editor.new()
      editor = Editor.put_metadata(editor, :my_plugin, %{state: :active})

      assert Editor.get_metadata(editor, :my_plugin) == %{state: :active}
    end

    test "can store multiple metadata keys" do
      editor = Editor.new()
      editor = Editor.put_metadata(editor, :key1, "value1")
      editor = Editor.put_metadata(editor, :key2, "value2")

      assert Editor.get_metadata(editor, :key1) == "value1"
      assert Editor.get_metadata(editor, :key2) == "value2"
    end
  end

  describe "get_metadata/2" do
    test "returns nil for missing key" do
      editor = Editor.new()
      assert Editor.get_metadata(editor, :missing) == nil
    end

    test "returns value for existing key" do
      editor = Editor.new()
      editor = Editor.put_metadata(editor, :key, "value")
      assert Editor.get_metadata(editor, :key) == "value"
    end
  end

  describe "clear_metadata/2" do
    test "removes metadata key" do
      editor = Editor.new()
      editor = Editor.put_metadata(editor, :key, "value")
      editor = Editor.clear_metadata(editor, :key)

      assert Editor.get_metadata(editor, :key) == nil
    end

    test "returns unchanged editor for missing key" do
      editor = Editor.new()
      editor2 = Editor.clear_metadata(editor, :missing)
      assert editor == editor2
    end
  end

  describe "notify/3" do
    test "notifies plugins of custom events" do
      editor = Editor.new(plugins: [TestPlugins.CustomPlugin])
      {:ok, editor} = Editor.notify(editor, :custom, %{data: "test"})

      assert Editor.get_metadata(editor, :custom) == %{data: "test"}
    end

    test "returns error when plugin rejects event" do
      editor = Editor.new(plugins: [TestPlugins.RejectCustomPlugin])

      assert {:error, :rejected} = Editor.notify(editor, :reject_me, nil)
    end
  end

  describe "undo/1" do
    test "returns error when no history" do
      editor = Editor.new()
      assert {:error, :no_history} = Editor.undo(editor)
    end

    test "undoes to initial content after single change" do
      editor = Editor.new(content: "initial")
      {:ok, editor} = Editor.set_content(editor, "second")

      assert Editor.can_undo?(editor)
      {:ok, editor} = Editor.undo(editor)
      assert Editor.get_content(editor) == "initial"
    end

    test "undoes to previous content after multiple changes" do
      editor = Editor.new(content: "first")
      {:ok, editor} = Editor.set_content(editor, "second")
      {:ok, editor} = Editor.set_content(editor, "third")

      assert Editor.can_undo?(editor)
      {:ok, editor} = Editor.undo(editor)
      assert Editor.get_content(editor) == "second"
    end

    test "can undo multiple changes" do
      editor = Editor.new(content: "1")
      {:ok, editor} = Editor.set_content(editor, "2")
      {:ok, editor} = Editor.set_content(editor, "3")
      {:ok, editor} = Editor.set_content(editor, "4")

      {:ok, editor} = Editor.undo(editor)
      assert Editor.get_content(editor) == "3"

      {:ok, editor} = Editor.undo(editor)
      assert Editor.get_content(editor) == "2"

      {:ok, editor} = Editor.undo(editor)
      assert Editor.get_content(editor) == "1"
    end
  end

  describe "redo/1" do
    test "returns error when no redo available" do
      editor = Editor.new()
      assert {:error, :no_redo} = Editor.redo(editor)
    end

    test "redoes undone change" do
      editor = Editor.new(content: "first")
      {:ok, editor} = Editor.set_content(editor, "second")
      {:ok, editor} = Editor.set_content(editor, "third")
      {:ok, editor} = Editor.undo(editor)
      {:ok, editor} = Editor.redo(editor)

      assert Editor.get_content(editor) == "third"
    end

    test "new change clears redo stack" do
      editor = Editor.new(content: "first")
      {:ok, editor} = Editor.set_content(editor, "second")
      {:ok, editor} = Editor.set_content(editor, "third")
      {:ok, editor} = Editor.undo(editor)
      {:ok, editor} = Editor.set_content(editor, "fourth")

      assert {:error, :no_redo} = Editor.redo(editor)
    end
  end

  describe "can_undo?/1" do
    test "returns false for new editor" do
      editor = Editor.new()
      refute Editor.can_undo?(editor)
    end

    test "returns true after single change" do
      editor = Editor.new(content: "initial")
      {:ok, editor} = Editor.set_content(editor, "changed")
      assert Editor.can_undo?(editor)
    end

    test "returns true after multiple changes" do
      editor = Editor.new(content: "first")
      {:ok, editor} = Editor.set_content(editor, "second")
      {:ok, editor} = Editor.set_content(editor, "third")
      assert Editor.can_undo?(editor)
    end
  end

  describe "can_redo?/1" do
    test "returns false for new editor" do
      editor = Editor.new()
      refute Editor.can_redo?(editor)
    end

    test "returns true after undo" do
      editor = Editor.new(content: "first")
      {:ok, editor} = Editor.set_content(editor, "second")
      {:ok, editor} = Editor.set_content(editor, "third")
      {:ok, editor} = Editor.undo(editor)
      assert Editor.can_redo?(editor)
    end
  end

  describe "undo/1 with plugins" do
    test "plugins receive correct old and new content on undo" do
      test_pid = self()
      Process.put(:test_pid, test_pid)

      editor = Editor.new(plugins: [TestPlugins.UndoRedoTrackingPlugin], content: "initial")
      {:ok, editor} = Editor.set_content(editor, "changed")
      {:ok, _editor} = Editor.undo(editor)

      assert_receive {:handle_change, "changed", "initial"}
    end

    test "redo with plugins receives correct old and new content" do
      test_pid = self()
      Process.put(:test_pid, test_pid)

      editor = Editor.new(plugins: [TestPlugins.UndoRedoTrackingPlugin], content: "first")
      {:ok, editor} = Editor.set_content(editor, "second")
      {:ok, editor} = Editor.undo(editor)

      # After undo, we should be able to redo
      assert Editor.can_redo?(editor), "should be able to redo after undo"

      # Clear mailbox from undo
      receive do
        {:handle_change, _, _} -> :ok
      after
        0 -> :ok
      end

      {:ok, _editor} = Editor.redo(editor)

      assert_receive {:handle_change, "first", "second"}
    end
  end

  describe "set_content/2 with unchanged content" do
    test "still pushes to history when content is unchanged" do
      editor = Editor.new(content: "same")
      {:ok, editor} = Editor.set_content(editor, "same")

      # Content is unchanged but history should still have an entry
      assert Editor.can_undo?(editor)
      {:ok, editor} = Editor.undo(editor)
      assert Editor.get_content(editor) == "same"
    end
  end

  describe "notify/3 with multiple plugins" do
    test "custom events propagate through plugin chain" do
      editor = Editor.new(plugins: [TestPlugins.ChainPlugin1, TestPlugins.ChainPlugin2])
      {:ok, editor} = Editor.notify(editor, :chain_event, nil)

      # Both plugins should have processed the event
      assert Editor.get_metadata(editor, :chain1) == :processed
      assert Editor.get_metadata(editor, :chain2) == :processed
    end

    test "editor state from plugin 1 reaches plugin 2" do
      editor =
        Editor.new(plugins: [TestPlugins.ChainMetadataSetter, TestPlugins.ChainMetadataReader])

      {:ok, editor} = Editor.notify(editor, :set_and_read, "test_value")

      # Plugin 1 sets metadata, plugin 2 reads and transforms it
      assert Editor.get_metadata(editor, :transformed) == "TEST_VALUE_transformed"
    end
  end

  describe "apply_diff/4" do
    test "inserts text at position" do
      assert {:ok, "hallo"} = Editor.apply_diff("hllo", 1, 1, "a")
    end

    test "deletes text by replacement with empty string" do
      assert {:ok, "helo"} = Editor.apply_diff("hello", 3, 4, "")
    end

    test "replaces range of text" do
      assert {:ok, "hello world"} = Editor.apply_diff("hello there", 6, 11, "world")
    end

    test "inserts at start" do
      assert {:ok, "prefix_hello"} = Editor.apply_diff("hello", 0, 0, "prefix_")
    end

    test "appends at end" do
      assert {:ok, "hello_suffix"} = Editor.apply_diff("hello", 5, 5, "_suffix")
    end

    test "returns error for negative from position" do
      assert {:error, :out_of_bounds} = Editor.apply_diff("hello", -1, 2, "x")
    end

    test "returns error when to < from" do
      assert {:error, :out_of_bounds} = Editor.apply_diff("hello", 3, 1, "x")
    end

    test "returns error when to exceeds content length" do
      assert {:error, :out_of_bounds} = Editor.apply_diff("hello", 0, 10, "x")
    end

    test "returns error when from exceeds content length" do
      assert {:error, :out_of_bounds} = Editor.apply_diff("hello", 10, 11, "x")
    end

    test "handles unicode characters" do
      # Elixir String.length counts codepoints, not bytes
      assert {:ok, "héllo"} = Editor.apply_diff("hllo", 1, 1, "é")
    end

    test "handles empty string content" do
      assert {:ok, "hello"} = Editor.apply_diff("", 0, 0, "hello")
    end

    test "handles large replacements" do
      long_text = String.duplicate("x", 1000)
      result = Editor.apply_diff("hello world", 0, 11, long_text)
      assert {:ok, ^long_text} = result
    end
  end
end

defmodule TestPlugins.MyPlugin do
  @behaviour ExEditor.Plugin
  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule TestPlugins.MockPlugin do
  @behaviour ExEditor.Plugin

  @impl true
  def on_event(:handle_change, _payload, editor) do
    send(Process.get(:test_pid), {:plugin_event, :handle_change})
    {:ok, editor}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule TestPlugins.RejectPlugin do
  @behaviour ExEditor.Plugin

  @impl true
  def on_event(:before_change, {_old, new}, editor) do
    if String.contains?(new, "forbidden") do
      {:error, :forbidden_word}
    else
      {:ok, editor}
    end
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule TestPlugins.MetaPlugin do
  @behaviour ExEditor.Plugin

  alias ExEditor.Editor

  @impl true
  def on_event(:handle_change, {_old, new}, editor) do
    {:ok, Editor.put_metadata(editor, :change_count, String.length(new))}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule TestPlugins.CounterPlugin do
  @behaviour ExEditor.Plugin

  alias ExEditor.Editor

  @impl true
  def on_event(:handle_change, _, editor) do
    count = Editor.get_metadata(editor, :count) || 0
    {:ok, Editor.put_metadata(editor, :count, count + 1)}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule TestPlugins.ErrorOnHandleChangePlugin do
  @behaviour ExEditor.Plugin

  @impl true
  def on_event(:handle_change, _, _editor) do
    {:error, :something_went_wrong}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule TestPlugins.CustomPlugin do
  @behaviour ExEditor.Plugin

  alias ExEditor.Editor

  @impl true
  def on_event(:custom, payload, editor) do
    {:ok, Editor.put_metadata(editor, :custom, payload)}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule TestPlugins.RejectCustomPlugin do
  @behaviour ExEditor.Plugin

  @impl true
  def on_event(:reject_me, _payload, _editor) do
    {:error, :rejected}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule TestPlugins.UndoRedoTrackingPlugin do
  @behaviour ExEditor.Plugin

  @impl true
  def on_event(:handle_change, {old_content, new_content}, editor) do
    send(Process.get(:test_pid), {:handle_change, old_content, new_content})
    {:ok, editor}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule TestPlugins.ChainPlugin1 do
  @behaviour ExEditor.Plugin

  alias ExEditor.Editor

  @impl true
  def on_event(:chain_event, _payload, editor) do
    {:ok, Editor.put_metadata(editor, :chain1, :processed)}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule TestPlugins.ChainPlugin2 do
  @behaviour ExEditor.Plugin

  alias ExEditor.Editor

  @impl true
  def on_event(:chain_event, _payload, editor) do
    {:ok, Editor.put_metadata(editor, :chain2, :processed)}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule TestPlugins.ChainMetadataSetter do
  @behaviour ExEditor.Plugin

  alias ExEditor.Editor

  @impl true
  def on_event(:set_and_read, value, editor) do
    {:ok, Editor.put_metadata(editor, :value, String.upcase(value))}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end

defmodule TestPlugins.ChainMetadataReader do
  @behaviour ExEditor.Plugin

  alias ExEditor.Editor

  @impl true
  def on_event(:set_and_read, _payload, editor) do
    value = Editor.get_metadata(editor, :value)
    {:ok, Editor.put_metadata(editor, :transformed, "#{value}_transformed")}
  end

  @impl true
  def on_event(_event, _payload, editor), do: {:ok, editor}
end
