defmodule DemoWeb.EditorLiveTest do
  use DemoWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "mount" do
    test "initializes with sample Elixir code", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")

      assert view
      assert html =~ "ExEditor Demo"
      assert html =~ "defmodule Example"
      assert html =~ "def hello"

      # Verify EditorHook is attached
      assert html =~ ~s(phx-hook="EditorHook")
      assert html =~ "ex-editor-container"
    end

    test "assigns code on mount", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      assert view |> element("textarea.ex-editor-textarea") |> has_element?()
    end

    test "renders line numbers", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "ex-editor-gutter"
      assert html =~ "ex-editor-line-number"
    end
  end

  describe "handle_event/3 code_changed" do
    test "updates raw content preview when content changes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Content changes are pushed via JS hook to the component,
      # then the component sends handle_info to the parent.
      # In tests we can send the event directly to the component.
      new_content = "defmodule NewCode do\n  def test, do: :ok\nend"

      send(view.pid, {:code_changed, %{content: new_content}})

      html = render(view)
      assert html =~ "defmodule NewCode"
      assert html =~ "def test, do: :ok"
    end

    test "handles empty content", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      send(view.pid, {:code_changed, %{content: ""}})

      html = render(view)
      assert html =~ "ExEditor Demo"
    end
  end

  describe "render/1" do
    test "renders LiveEditor component", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "ex-editor-container"
      assert html =~ "ex-editor-highlight"
      assert html =~ "ex-editor-textarea"
    end

    test "applies dark theme styling", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "bg-[#1e1e1e]"
      assert html =~ "text-[#d4d4d4]"
    end

    test "renders syntax highlighting classes", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "hl-keyword"
    end

    test "shows raw content preview", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Raw Content (Preview)"
    end
  end
end
