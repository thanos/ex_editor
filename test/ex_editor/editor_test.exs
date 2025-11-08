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
    end

    test "creates a new editor with provided content" do
      editor = Editor.new(content: "hello world")
      assert %Editor{} = editor
      assert ExEditor.Document.to_text(editor.document) == "hello world"
    end

    test "creates a new editor with provided plugins" do
      defmodule MyPlugin do
        @behaviour ExEditor.Plugin
        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

      editor = Editor.new(plugins: [MyPlugin])
      assert editor.plugins == [MyPlugin]
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
      # Mock plugin behavior
      test_pid = self()

      receive_messages_pid = self()

      defmodule MockPlugin do
        @behaviour ExEditor.Plugin
        def on_event(:handle_change, _payload, editor) do
          send(test_pid, {:plugin_event, :handle_change})
          {:ok, editor}
        end

        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

      editor = Editor.new(plugins: [MockPlugin], content: "initial")
      {:ok, _updated_editor} = Editor.set_content(editor, "changed content")

      assert_receive {:plugin_event, :handle_change}
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
end
