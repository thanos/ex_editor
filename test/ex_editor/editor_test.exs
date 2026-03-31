defmodule ExEditor.EditorTest do
  use ExUnit.Case
  alias ExEditor.Document
  alias ExEditor.Editor

  describe "new/1" do
    test "creates a new editor with an empty document by default" do
      {:ok, editor} = Editor.new()
      assert %Editor{document: %Document{lines: [""]}} = editor
      assert editor.plugins == []
      assert editor.options == []
      assert editor.metadata == %{}
    end

    test "creates a new editor with provided content" do
      {:ok, editor} = Editor.new(content: "hello world")
      assert %Editor{} = editor
      assert ExEditor.Document.to_text(editor.document) == "hello world"
    end

    test "creates a new editor with provided plugins" do
      defmodule MyPlugin do
        @behaviour ExEditor.Plugin
        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

      {:ok, editor} = Editor.new(plugins: [MyPlugin])
      assert editor.plugins == [MyPlugin]
    end
  end

  describe "set_content/2" do
    test "sets new content for the editor" do
      {:ok, editor} = Editor.new(content: "old content")
      {:ok, updated_editor} = Editor.set_content(editor, "new content")
      assert ExEditor.Document.to_text(updated_editor.document) == "new content"
    end

    test "returns error for invalid content" do
      {:ok, editor} = Editor.new()
      {:error, :invalid_content} = Editor.set_content(editor, nil)
    end

    test "notifies plugins of content change" do
      test_pid = self()

      defmodule MockPlugin do
        @behaviour ExEditor.Plugin

        def on_event(:handle_change, _payload, editor) do
          send(Process.get(:test_pid), {:plugin_event, :handle_change})
          {:ok, editor}
        end

        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

      Process.put(:test_pid, test_pid)

      {:ok, editor} = Editor.new(plugins: [MockPlugin], content: "initial")
      {:ok, _updated_editor} = Editor.set_content(editor, "changed content")

      assert_receive {:plugin_event, :handle_change}
    end

    test "before_change event can reject changes" do
      defmodule RejectPlugin do
        @behaviour ExEditor.Plugin

        def on_event(:before_change, {_old, new}, editor) do
          if String.contains?(new, "forbidden") do
            {:error, :forbidden_word}
          else
            {:ok, editor}
          end
        end

        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

      {:ok, editor} = Editor.new(plugins: [RejectPlugin])

      assert {:error, :forbidden_word} = Editor.set_content(editor, "forbidden content")
      assert {:ok, _} = Editor.set_content(editor, "allowed content")
    end

    test "plugins can modify editor via metadata" do
      defmodule MetaPlugin do
        @behaviour ExEditor.Plugin

        def on_event(:handle_change, {_old, new}, editor) do
          {:ok, Editor.put_metadata(editor, :change_count, String.length(new))}
        end

        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

      {:ok, editor} = Editor.new(plugins: [MetaPlugin])
      {:ok, editor} = Editor.set_content(editor, "hello")

      assert editor.metadata[:change_count] == 5
    end

    test "multiple plugins form middleware chain" do
      defmodule CounterPlugin do
        @behaviour ExEditor.Plugin

        def on_event(:handle_change, _, editor) do
          count = Map.get(editor.metadata, :count, 0)
          {:ok, Editor.put_metadata(editor, :count, count + 1)}
        end

        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

      {:ok, editor} = Editor.new(plugins: [CounterPlugin, CounterPlugin])
      {:ok, editor} = Editor.set_content(editor, "test")

      assert editor.metadata[:count] == 2
    end
  end

  describe "get_content/1" do
    test "returns the current content of the editor" do
      {:ok, editor} = Editor.new(content: "some text")
      assert Editor.get_content(editor) == "some text"
    end

    test "returns empty string for new editor" do
      {:ok, editor} = Editor.new()
      assert Editor.get_content(editor) == ""
    end
  end

  describe "put_metadata/3" do
    test "stores metadata in the editor" do
      {:ok, editor} = Editor.new()
      editor = Editor.put_metadata(editor, :my_plugin, %{state: :active})

      assert editor.metadata[:my_plugin] == %{state: :active}
    end

    test "can store multiple metadata keys" do
      {:ok, editor} = Editor.new()
      editor = Editor.put_metadata(editor, :key1, "value1")
      editor = Editor.put_metadata(editor, :key2, "value2")

      assert editor.metadata[:key1] == "value1"
      assert editor.metadata[:key2] == "value2"
    end
  end

  describe "notify/3" do
    test "notifies plugins of custom events" do
      defmodule CustomPlugin do
        @behaviour ExEditor.Plugin

        def on_event(:custom, payload, editor) do
          {:ok, Editor.put_metadata(editor, :custom, payload)}
        end

        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

      {:ok, editor} = Editor.new(plugins: [CustomPlugin])
      {:ok, editor} = Editor.notify(editor, :custom, %{data: "test"})

      assert editor.metadata[:custom] == %{data: "test"}
    end

    test "returns error when plugin rejects event" do
      defmodule RejectCustomPlugin do
        @behaviour ExEditor.Plugin

        def on_event(:reject_me, _payload, _editor) do
          {:error, :rejected}
        end

        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

      {:ok, editor} = Editor.new(plugins: [RejectCustomPlugin])

      assert {:error, :rejected} = Editor.notify(editor, :reject_me, nil)
    end
  end
end
