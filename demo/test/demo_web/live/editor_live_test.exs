defmodule DemoWeb.EditorLiveTest do
  use DemoWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "mount" do
    test "initializes with sample Elixir code", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")

      assert view
      assert html =~ "ExEditor Demo"

      # Verify sample code is loaded in both textarea and highlighted content
      assert html =~ "defmodule Example"
      assert html =~ "def hello"

      # Verify EditorHook is attached
      assert html =~ ~s(phx-hook="EditorHook")

      # Verify the LiveEditor component is rendered
      assert html =~ "ex-editor-container"
      assert html =~ "ex-editor-textarea"
      assert html =~ "ex-editor-highlight"
    end

    test "assigns code on mount", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Verify the textarea exists within the LiveEditor component
      assert view |> element("textarea.ex-editor-textarea") |> has_element?()
    end

    test "renders line numbers", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Verify line numbers are present
      assert html =~ "ex-editor-line-numbers"
      assert html =~ "1\n2\n3"
    end
  end

  describe "handle_event/3 code_changed" do
    test "updates editor content when user types", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Simulate user typing new content via the LiveEditor component
      new_content = "defmodule NewCode do\n  def test, do: :ok\nend"

      # Target the textarea within the LiveEditor component
      view
      |> element("textarea.ex-editor-textarea")
      |> render_change(%{"content" => new_content})

      # Verify content updated
      html = render(view)
      assert html =~ "defmodule NewCode"
      assert html =~ "def test, do: :ok"
    end

    test "handles empty content", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("textarea.ex-editor-textarea")
      |> render_change(%{"content" => ""})

      html = render(view)
      assert html =~ "ExEditor Demo"
    end

    test "handles multiline content", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      multiline = """
      line 1
      line 2
      line 3
      line 4
      """

      view
      |> element("textarea.ex-editor-textarea")
      |> render_change(%{"content" => multiline})

      html = render(view)
      assert html =~ "line 1"
      assert html =~ "line 2"
      assert html =~ "line 3"
      assert html =~ "line 4"
    end
  end

  describe "render/1" do
    test "renders LiveEditor component", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Verify the LiveEditor component structure
      assert html =~ "ex-editor-container"
      assert html =~ "ex-editor-wrapper"
      assert html =~ "ex-editor-textarea"
      assert html =~ "ex-editor-highlight"
    end

    test "applies dark theme styling", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Verify dark background
      assert html =~ "bg-[#1e1e1e]"

      # Verify text color
      assert html =~ "text-[#d4d4d4]"
    end

    test "renders syntax highlighting classes", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Verify syntax highlighting classes are applied
      assert html =~ "hl-keyword"
    end

    test "shows raw content preview", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Verify raw content preview section exists
      assert html =~ "Raw Content (Preview)"
    end
  end
end
