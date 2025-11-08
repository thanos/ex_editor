defmodule DemoWeb.EditorLiveTest do
  use DemoWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "mount" do
    test "initializes with sample Elixir code", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")

      # Verify the view mounted successfully
      assert view
      assert html =~ "ExEditor Demo"

      # Verify sample code is loaded
      assert html =~ "defmodule Example"
      assert html =~ "def hello"

      # Verify cursor position badge is rendered
      assert html =~ "Ln 1, Col 1"

      # Verify EditorSync hook is attached
      assert html =~ "phx-hook=\"EditorSync\""
    end

    test "assigns editor and content on mount", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Check assigns are set correctly
      assert view |> element("textarea[name='content']") |> has_element?()
      assert view |> element("#raw-content") |> has_element?()
    end
  end

  describe "handle_event/3 update_content" do
    test "updates editor content when user types", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Simulate user typing new content
      new_content = "defmodule NewCode do\n  def test, do: :ok\nend"

      view
      |> element("form")
      |> render_change(%{"content" => new_content})

      # Verify content updated in the view
      html = render(view)
      assert html =~ "defmodule NewCode"
      assert html =~ "def test, do: :ok"
    end

    test "handles empty content", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("form")
      |> render_change(%{"content" => ""})

      # Should handle empty content gracefully
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
      |> element("form")
      |> render_change(%{"content" => multiline})

      html = render(view)
      assert html =~ "line 1"
      assert html =~ "line 2"
      assert html =~ "line 3"
      assert html =~ "line 4"
    end
  end

  describe "handle_event/3 update_cursor" do
    test "updates cursor position when user moves cursor", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Simulate cursor movement
      view
      |> render_hook("update_cursor", %{
        "line" => 5,
        "col" => 10
      })

      # Verify cursor position updated
      html = render(view)
      assert html =~ "Ln 5, Col 10"
    end

    test "handles cursor at line 1, col 1", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> render_hook("update_cursor", %{
        "line" => 1,
        "col" => 1
      })

      html = render(view)
      assert html =~ "Ln 1, Col 1"
    end

    test "handles large line numbers", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> render_hook("update_cursor", %{
        "line" => 999,
        "col" => 50
      })

      html = render(view)
      assert html =~ "Ln 999, Col 50"
    end
  end

  describe "render/1" do
    test "renders side-by-side editor layout", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Verify grid layout
      assert html =~ "grid grid-cols-2"

      # Verify textarea editor
      assert html =~ "<textarea"
      assert html =~ "name=\"content\""
      assert html =~ "phx-change=\"update_content\""

      # Verify raw content display
      assert html =~ "id=\"raw-content\""
    end

    test "applies dark theme styling", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Verify dark background
      assert html =~ "bg-[#1e1e1e]"

      # Verify text color
      assert html =~ "text-[#d4d4d4]"
    end

    test "renders cursor position badge", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "cursor-position"
      assert html =~ "Ln"
      assert html =~ "Col"
    end
  end
end
