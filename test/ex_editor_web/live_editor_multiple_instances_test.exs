defmodule ExEditorWeb.LiveEditorMultipleInstancesTest do
  @moduledoc """
  Tests to verify that multiple ExEditorWeb.LiveEditor components can be used
  in the same LiveView session without cross-contamination of values.

  This is a regression test for the bug where the args field would get the
  code field's value when both were present in the same form.
  """
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  setup do
    # Use unique name for each test to avoid conflicts
    pubsub_name = :"test_pubsub_#{System.unique_integer()}"
    {:ok, _pid} = start_supervised(Phoenix.PubSub.child_spec(name: pubsub_name))
    :ok
  end

  describe "multiple LiveEditor instances" do
    test "each instance maintains its own content" do
      # Render two editors with different content
      html1 =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "editor_code",
          content: "def hello, do: :world",
          language: :elixir,
          on_change: "code_changed"
        })

      html2 =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "editor_args",
          content: ~s({"key": "value"}),
          language: :json,
          on_change: "args_changed"
        })

      # Both should be rendered
      assert html1 =~ "def hello, do: :world"
      # HTML escapes quotes, so check for the escaped version
      assert html2 =~ "&quot;key&quot;"
      assert html2 =~ "&quot;value&quot;"

      # They should have different IDs
      assert html1 =~ ~s(id="editor_code")
      assert html2 =~ ~s(id="editor_args")

      # They should have their correct textareas
      assert html1 =~ ~s(id="editor_code-textarea")
      assert html2 =~ ~s(id="editor_args-textarea")
    end

    test "each instance has separate hook instances" do
      # When rendered, each should have EditorHook on its own container
      html1 =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "editor_code",
          content: "code"
        })

      html2 =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "editor_args",
          content: "args"
        })

      # Both should have their own EditorHook
      # The hook is on the container div with phx-hook="EditorHook"
      assert html1 =~ ~s(id="editor_code") and html1 =~ ~s(phx-hook="EditorHook")
      assert html2 =~ ~s(id="editor_args") and html2 =~ ~s(phx-hook="EditorHook")
    end

    test "each instance has unique gutter elements" do
      html1 =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "editor_code",
          content: "line1\nline2",
          line_numbers: true
        })

      html2 =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "editor_args",
          content: "line1\nline2\nline3",
          line_numbers: true
        })

      # Each should have unique gutter IDs
      assert html1 =~ ~s(id="editor_code-gutter")
      assert html2 =~ ~s(id="editor_args-gutter")
    end

    test "editor state is independent per component instance" do
      # Each component should maintain its own state independently
      # Render two editors and verify their initial values persist separately

      html_first =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "editor_first",
          content: "initial_first",
          on_change: "first_changed"
        })

      html_second =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "editor_second",
          content: "initial_second",
          on_change: "second_changed"
        })

      # Each should render with its own content in the textarea
      assert html_first =~ "initial_first"
      assert html_second =~ "initial_second"

      # They should send changes to different event handlers
      assert html_first =~ ~s(phx-target=")
      assert html_second =~ ~s(phx-target=")

      # Both should have proper structure
      assert html_first =~ "ex-editor-container"
      assert html_second =~ "ex-editor-container"
    end

    test "each component receives debounce setting separately" do
      html1 =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "editor_code",
          content: "code",
          debounce: 100
        })

      html2 =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "editor_args",
          content: "args",
          debounce: 50
        })

      # Each should have its debounce setting
      assert html1 =~ ~s(data-debounce="100")
      assert html2 =~ ~s(data-debounce="50")
    end
  end
end
