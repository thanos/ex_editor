defmodule ExEditor.PluginTest do
  use ExUnit.Case, async: true

  # Test plugin implementations
  defmodule MaxLengthPlugin do
    @behaviour ExEditor.Plugin

    @max_length 20

    @impl true
    def on_event(:before_change, {_old, new}, editor) do
      if String.length(new) > @max_length do
        {:error, :too_long}
      else
        {:ok, editor}
      end
    end

    def on_event(_event, _payload, editor), do: {:ok, editor}
  end

  defmodule TrackingPlugin do
    @behaviour ExEditor.Plugin

    @impl true
    def on_event(:handle_change, {old, new}, editor) do
      {:ok, ExEditor.Editor.put_metadata(editor, :last_change, %{from: old, to: new})}
    end

    def on_event(_event, _payload, editor), do: {:ok, editor}
  end

  describe "Plugin behaviour" do
    test "plugin on_event/3 returns {:ok, editor}" do
      editor = ExEditor.new()
      result = MaxLengthPlugin.on_event(:unknown_event, nil, editor)
      assert {:ok, _editor} = result
    end

    test "plugin on_event/3 can return {:error, reason}" do
      editor = ExEditor.new(content: "short")
      long_content = String.duplicate("x", 25)
      result = MaxLengthPlugin.on_event(:before_change, {"short", long_content}, editor)
      assert {:error, :too_long} = result
    end
  end

  describe "Plugin integration with editor" do
    test "before_change plugin can reject changes" do
      editor = ExEditor.new(plugins: [MaxLengthPlugin])
      short_content = "short content"

      result = ExEditor.Editor.set_content(editor, short_content)
      assert {:ok, updated} = result
      assert ExEditor.Editor.get_content(updated) == short_content
    end

    test "before_change plugin blocks oversized content" do
      editor = ExEditor.new(plugins: [MaxLengthPlugin])
      long_content = String.duplicate("x", 25)

      result = ExEditor.Editor.set_content(editor, long_content)
      assert {:error, _} = result
    end

    test "handle_change plugin tracks changes" do
      editor = ExEditor.new(content: "old", plugins: [TrackingPlugin])
      new_content = "new"

      {:ok, updated} = ExEditor.Editor.set_content(editor, new_content)
      last_change = ExEditor.Editor.get_metadata(updated, :last_change)

      assert last_change == %{from: "old", to: new_content}
    end

    test "multiple plugins can be registered" do
      editor = ExEditor.new(plugins: [MaxLengthPlugin, TrackingPlugin])
      content = "valid content"

      {:ok, updated} = ExEditor.Editor.set_content(editor, content)
      assert ExEditor.Editor.get_content(updated) == content

      last_change = ExEditor.Editor.get_metadata(updated, :last_change)
      assert last_change == %{from: "", to: content}
    end
  end

  describe "Plugin error handling" do
    test "before_change error halts content update" do
      editor = ExEditor.new(plugins: [MaxLengthPlugin])
      long = String.duplicate("x", 25)

      {:error, reason} = ExEditor.Editor.set_content(editor, long)
      assert reason == :too_long
      # Content should not have changed
      assert ExEditor.Editor.get_content(editor) == ""
    end
  end
end
