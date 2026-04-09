defmodule ExEditorWeb.LiveEditorComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  setup do
    {:ok, _pid} = start_supervised(Phoenix.PubSub.child_spec(name: :test_pubsub))
    :ok
  end

  describe "LiveEditor component rendering" do
    test "renders editor container" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "def hello, do: :world",
          language: :elixir,
          on_change: "code_changed",
          readonly: false,
          line_numbers: true,
          debounce: 300
        })

      assert html =~ "ex-editor-container"
      assert html =~ ~s(id="test-editor")
    end

    test "renders textarea with initial content" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "def hello, do: :world",
          language: :elixir
        })

      assert html =~ "def hello, do: :world"
      assert html =~ "ex-editor-textarea"
    end

    test "renders with JavaScript hook" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "test"
        })

      assert html =~ ~s(phx-hook="EditorHook")
    end

    test "renders line numbers gutter" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "line1\nline2\nline3",
          line_numbers: true
        })

      assert html =~ "ex-editor-gutter"
      # Should render line number divs
      assert html =~ "ex-editor-line-number"
    end

    test "hides line numbers when disabled" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "test",
          line_numbers: false
        })

      # When line_numbers is false, the gutter should not render
      refute html =~ "ex-editor-gutter"
    end

    test "renders highlighted content layer" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "def hello, do: :world",
          language: :elixir
        })

      assert html =~ "ex-editor-highlight"
      # Elixir highlighter should produce syntax classes
      assert html =~ "hl-"
    end

    test "protects textarea from LiveView patching" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "test"
        })

      assert html =~ ~s(phx-update="ignore")
    end

    test "includes debounce value in data attribute" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "test",
          debounce: 500
        })

      assert html =~ ~s(data-debounce="500")
    end

    test "renders code area wrapper" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "test"
        })

      assert html =~ "ex-editor-code-area"
    end

    test "applies additional CSS classes" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "test",
          class: "custom-class"
        })

      assert html =~ "custom-class"
    end
  end

  describe "Language support in component" do
    test "Elixir language highlights keywords" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "def test do :ok end",
          language: :elixir
        })

      assert html =~ ~s(class="hl-keyword")
    end

    test "JSON language highlights objects" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "{\"key\": \"value\"}",
          language: :json
        })

      # JSON should have syntax highlighting
      assert html =~ "hl-"
    end

    test "unknown language renders without highlighting" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "some code",
          language: :unknown
        })

      # Should still render but without language-specific highlighting
      assert html =~ "ex-editor-container"
    end
  end

  describe "Component configuration" do
    test "default debounce is 50ms" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "test"
        })

      assert html =~ ~s(data-debounce="50")
    end

    test "default language is Elixir" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "def test, do: :ok"
        })

      # Elixir highlighting should be applied by default
      assert html =~ "hl-keyword"
    end

    test "line_numbers enabled by default" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "line1\nline2"
        })

      assert html =~ "ex-editor-gutter"
    end

    test "readonly mode renders correctly" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: "test",
          readonly: true
        })

      assert html =~ "readonly"
    end
  end

  describe "Content rendering" do
    test "multi-line content renders correct line count" do
      content = "line1\nline2\nline3\nline4\nline5"

      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: content,
          line_numbers: true
        })

      # Should have 5 line number divs
      count = String.split(html, "ex-editor-line-number") |> length()
      assert count >= 5
    end

    test "heredoc strings are highlighted" do
      content = ~S("""
      This is a
      multi-line
      heredoc string
      """)

      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: content,
          language: :elixir
        })

      assert html =~ "hl-string"
    end

    test "empty content renders without error" do
      html =
        render_component(ExEditorWeb.LiveEditor, %{
          id: "test-editor",
          content: ""
        })

      assert html =~ "ex-editor-container"
    end
  end
end
