defmodule ExEditorWeb.LiveEditorEventTest do
  use ExUnit.Case, async: true

  describe "LiveEditor change event processing" do
    test "change event updates editor content" do
      editor =
        ExEditor.new(content: "original")
        |> ExEditor.Editor.set_highlighter(ExEditor.Highlighters.Elixir)

      # Simulate what handle_event does
      {:ok, updated_editor} = ExEditor.Editor.set_content(editor, "new content")

      # Verify the update
      assert ExEditor.Editor.get_content(updated_editor) == "new content"
    end

    test "change event with syntax highlighting is applied" do
      editor =
        ExEditor.new(content: "old")
        |> ExEditor.Editor.set_highlighter(ExEditor.Highlighters.Elixir)

      # Change to code with keywords
      {:ok, updated} = ExEditor.Editor.set_content(editor, "def hello, do: :world")

      # Verify highlighting was applied
      highlighted = ExEditor.Editor.get_highlighted_content(updated)
      assert String.contains?(highlighted, "hl-keyword")
    end

    test "change event error handling - rejected by plugin" do
      defmodule RejectPlugin do
        @behaviour ExEditor.Plugin

        def on_event(:before_change, _, _editor) do
          {:error, :rejected}
        end

        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

      editor = ExEditor.new(content: "keep this", plugins: [RejectPlugin])

      # Try to change content (should be rejected)
      result = ExEditor.Editor.set_content(editor, "rejected")

      # Should return error
      assert {:error, :rejected} = result
      # Original content should be unchanged
      assert ExEditor.Editor.get_content(editor) == "keep this"
    end

    test "change event with empty content" do
      editor = ExEditor.new(content: "something")

      # Change to empty
      {:ok, updated} = ExEditor.Editor.set_content(editor, "")

      assert ExEditor.Editor.get_content(updated) == ""
    end

    test "change event with multi-line content" do
      editor = ExEditor.new(content: "single line")

      # Change to multi-line
      multi = "line1\nline2\nline3\nline4"
      {:ok, updated} = ExEditor.Editor.set_content(editor, multi)

      # Verify all lines are present
      assert ExEditor.Editor.get_content(updated) == multi
      # Verify line count
      count = ExEditor.Document.line_count(updated.document)
      assert count == 4
    end

    test "change event with special characters" do
      editor =
        ExEditor.new(content: "test")
        |> ExEditor.Editor.set_highlighter(ExEditor.Highlighters.Elixir)

      special = ~S(puts "Hello\nWorld")
      {:ok, updated} = ExEditor.Editor.set_content(editor, special)

      assert ExEditor.Editor.get_content(updated) == special
    end

    test "change event with heredoc strings" do
      editor =
        ExEditor.new(content: "old")
        |> ExEditor.Editor.set_highlighter(ExEditor.Highlighters.Elixir)

      heredoc = ~S("""
      multi
      line
      string
      """)
      {:ok, updated} = ExEditor.Editor.set_content(editor, heredoc)

      # Verify structure is maintained
      content = ExEditor.Editor.get_content(updated)
      assert String.contains?(content, ["multi", "line", "string"])

      # Verify highlighting
      highlighted = ExEditor.Editor.get_highlighted_content(updated)
      assert String.contains?(highlighted, "hl-string")
    end

    test "change event preserves line count accuracy" do
      editor = ExEditor.new(content: "line1\nline2")
      count1 = ExEditor.Document.line_count(editor.document)
      assert count1 == 2

      {:ok, updated} = ExEditor.Editor.set_content(editor, "line1\nline2\nline3\nline4")
      count2 = ExEditor.Document.line_count(updated.document)
      assert count2 == 4
    end

    test "change event with Elixir code" do
      editor =
        ExEditor.new(content: "test")
        |> ExEditor.Editor.set_highlighter(ExEditor.Highlighters.Elixir)

      code = "def test, do: :ok"
      {:ok, updated} = ExEditor.Editor.set_content(editor, code)

      highlighted = ExEditor.Editor.get_highlighted_content(updated)
      assert String.contains?(highlighted, "hl-keyword")
    end

    test "change event with JSON content" do
      editor =
        ExEditor.new(content: "test")
        |> ExEditor.Editor.set_highlighter(ExEditor.Highlighters.JSON)

      json = "{\"key\": \"value\"}"
      {:ok, updated} = ExEditor.Editor.set_content(editor, json)

      highlighted = ExEditor.Editor.get_highlighted_content(updated)
      # JSON highlighter should produce some highlighting
      assert String.contains?(highlighted, "<span")
    end

    test "change event with very large content" do
      editor = ExEditor.new(content: "start")

      # Create large content
      large = String.duplicate("line\n", 100)
      {:ok, updated} = ExEditor.Editor.set_content(editor, large)

      # Verify size
      content = ExEditor.Editor.get_content(updated)
      assert String.length(content) == String.length(large)

      # Verify line count
      count = ExEditor.Document.line_count(updated.document)
      # 100 "line\n" + 1 final empty line
      assert count == 101
    end

    test "sequential change events maintain state" do
      editor = ExEditor.new(content: "first")

      # First change
      {:ok, second} = ExEditor.Editor.set_content(editor, "second")
      assert ExEditor.Editor.get_content(second) == "second"

      # Second change
      {:ok, third} = ExEditor.Editor.set_content(second, "third")
      assert ExEditor.Editor.get_content(third) == "third"

      # Verify history is maintained
      {:ok, undone} = ExEditor.Editor.undo(third)
      assert ExEditor.Editor.get_content(undone) == "second"
    end

    test "change event with plugins tracking changes" do
      defmodule TrackingPlugin do
        @behaviour ExEditor.Plugin

        def on_event(:handle_change, {old, new}, editor) do
          {:ok, ExEditor.Editor.put_metadata(editor, :last_change, %{from: old, to: new})}
        end

        def on_event(_event, _payload, editor), do: {:ok, editor}
      end

      editor = ExEditor.new(content: "old", plugins: [TrackingPlugin])

      {:ok, updated} = ExEditor.Editor.set_content(editor, "new")

      # Verify plugin tracked the change
      change = ExEditor.Editor.get_metadata(updated, :last_change)
      assert change == %{from: "old", to: "new"}
    end
  end
end
