defmodule ExEditor.EditorTest do
  use ExUnit.Case, async: true
  doctest ExEditor.Editor

  alias ExEditor.Editor
  alias ExEditor.Document

  describe "new/0" do
    test "creates an editor with empty document" do
      editor = Editor.new()
      assert %Editor{} = editor
      assert editor.document == %Document{lines: [""]}
      assert editor.plugins == []
      assert editor.options == []
    end
  end

  describe "new/1 with options" do
    test "creates editor with initial content" do
      editor = Editor.new(content: "hello\nworld")
      assert editor.document.lines == ["hello", "world"]
    end

    test "creates editor with plugins" do
      editor = Editor.new(plugins: [SomePlugin])
      assert editor.plugins == [SomePlugin]
    end

    test "creates editor with multiple options" do
      editor = Editor.new(content: "test", plugins: [Plugin1, Plugin2])
      assert editor.document.lines == ["test"]
      assert editor.plugins == [Plugin1, Plugin2]
    end

    test "stores options for later use" do
      editor = Editor.new(content: "test", custom_option: "value")
      assert Keyword.get(editor.options, :custom_option) == "value"
    end
  end

  describe "set_content/2" do
    test "updates editor with new content" do
      editor = Editor.new()
      {:ok, updated} = Editor.set_content(editor, "new content")
      assert Document.to_text(updated.document) == "new content"
    end

    test "replaces existing content" do
      editor = Editor.new(content: "old content")
      {:ok, updated} = Editor.set_content(editor, "new content")
      assert Document.to_text(updated.document) == "new content"
    end

    test "handles multi-line content" do
      editor = Editor.new()
      {:ok, updated} = Editor.set_content(editor, "line1\nline2\nline3")
      assert updated.document.lines == ["line1", "line2", "line3"]
    end

    test "handles empty string" do
      editor = Editor.new(content: "some content")
      {:ok, updated} = Editor.set_content(editor, "")
      assert Document.to_text(updated.document) == ""
    end

    test "returns error for non-string content" do
      editor = Editor.new()
      assert {:error, _} = Editor.set_content(editor, 123)
    end

    test "notifies plugins on content change" do
      # Test plugin that tracks calls
      defmodule TestPlugin do
        def on_event(:handle_change, _payload, editor) do
          updated_opts = Keyword.put(editor.options, :plugin_called, true)
          {:ok, %{editor | options: updated_opts}}
        end
      end

      editor = Editor.new(plugins: [TestPlugin])
      {:ok, updated} = Editor.set_content(editor, "new content")

      assert Keyword.get(updated.options, :plugin_called) == true
    end

    test "handles plugin errors gracefully" do
      # Test plugin that returns an error
      defmodule ErrorPlugin do
        def on_event(:handle_change, _payload, _editor) do
          {:error, :plugin_error}
        end
      end

      editor = Editor.new(plugins: [ErrorPlugin])
      assert {:error, :plugin_error} = Editor.set_content(editor, "new content")
    end
  end

  describe "get_content/1" do
    test "returns empty string for new editor" do
      editor = Editor.new()
      assert Editor.get_content(editor) == ""
    end

    test "returns single line content" do
      editor = Editor.new(content: "hello world")
      assert Editor.get_content(editor) == "hello world"
    end

    test "returns multi-line content" do
      editor = Editor.new(content: "line1\nline2\nline3")
      assert Editor.get_content(editor) == "line1\nline2\nline3"
    end

    test "preserves empty lines" do
      editor = Editor.new(content: "line1\n\nline3")
      assert Editor.get_content(editor) == "line1\n\nline3"
    end

    test "preserves trailing newline" do
      editor = Editor.new(content: "line1\nline2\n")
      assert Editor.get_content(editor) == "line1\nline2\n"
    end
  end

  describe "plugin system" do
    test "editor without plugins works normally" do
      editor = Editor.new(plugins: [])
      {:ok, updated} = Editor.set_content(editor, "test")
      assert Editor.get_content(updated) == "test"
    end

    test "multiple plugins are called in order" do
      defmodule Plugin1 do
        def on_event(:handle_change, _payload, editor) do
          opts = Keyword.put(editor.options, :plugin1_called, true)
          {:ok, %{editor | options: opts}}
        end
      end

      defmodule Plugin2 do
        def on_event(:handle_change, _payload, editor) do
          opts = Keyword.put(editor.options, :plugin2_called, true)
          {:ok, %{editor | options: opts}}
        end
      end

      editor = Editor.new(plugins: [Plugin1, Plugin2])
      {:ok, updated} = Editor.set_content(editor, "test")

      assert Keyword.get(updated.options, :plugin1_called) == true
      assert Keyword.get(updated.options, :plugin2_called) == true
    end

    test "plugin chain stops on first error" do
      defmodule OkPlugin do
        def on_event(:handle_change, _payload, editor) do
          opts = Keyword.put(editor.options, :ok_plugin_called, true)
          {:ok, %{editor | options: opts}}
        end
      end

      defmodule FailPlugin do
        def on_event(:handle_change, _payload, _editor) do
          {:error, :fail_plugin_error}
        end
      end

      defmodule NeverCalledPlugin do
        def on_event(:handle_change, _payload, editor) do
          opts = Keyword.put(editor.options, :never_called, true)
          {:ok, %{editor | options: opts}}
        end
      end

      editor = Editor.new(plugins: [OkPlugin, FailPlugin, NeverCalledPlugin])
      assert {:error, :fail_plugin_error} = Editor.set_content(editor, "test")
    end

    test "plugins without on_event/3 are skipped" do
      defmodule NoHookPlugin do
        # This plugin doesn't implement on_event/3
      end

      editor = Editor.new(plugins: [NoHookPlugin])
      {:ok, updated} = Editor.set_content(editor, "test")
      assert Editor.get_content(updated) == "test"
    end
  end

  describe "edge cases" do
    test "handles very large documents" do
      large_content = Enum.map_join(1..1000, "\n", &"Line #{&1}")
      editor = Editor.new(content: large_content)
      assert String.contains?(Editor.get_content(editor), "Line 500")
      assert editor.document.lines |> length() == 1000
    end

    test "handles unicode content" do
      unicode = "Hello 世界 🌍\nΓεια σου κόσμε\nمرحبا بالعالم"
      editor = Editor.new(content: unicode)
      assert Editor.get_content(editor) == unicode
    end

    test "handles special characters" do
      special = "tabs\there\nquotes\"and'more\nnewlines\\n"
      editor = Editor.new(content: special)
      assert Editor.get_content(editor) == special
    end

    test "content roundtrip maintains integrity" do
      original = "line1\n\nline3\n  indented\n\t\ttabs\n"
      editor = Editor.new(content: original)
      {:ok, updated} = Editor.set_content(editor, original)
      assert Editor.get_content(updated) == original
    end
  end
end
