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
