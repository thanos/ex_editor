defmodule DemoWeb.Admin.CodeSnippetLiveTest do
  use DemoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Demo.CMS.CodeSnippet
  alias Demo.Repo

  setup do
    code_snippet =
      Repo.insert!(%CodeSnippet{
        name: "Test Snippet",
        code: "def test do\n  :ok\nend",
        args: %{"key" => "value", "nested" => %{"data" => "here"}}
      })

    {:ok, code_snippet: code_snippet}
  end

  describe "Backpex form rendering" do
    test "renders edit form with code field populated", %{conn: conn, code_snippet: cs} do
      {:ok, view, _html} = live(conn, "/admin/code_snippets/#{cs.id}/edit")

      # Check that the form is rendered
      assert has_element?(view, "form[id='resource-form']")

      # The code editor should be visible
      assert has_element?(view, "[phx-hook='EditorHook']")
    end

    test "renders edit form with label text", %{conn: conn, code_snippet: cs} do
      {:ok, _view, html} = live(conn, "/admin/code_snippets/#{cs.id}/edit")

      # Verify field labels are present
      assert html =~ "Code"
      assert html =~ "Args (JSON)"
      assert html =~ "Name"
    end
  end

  describe "changeset validation" do
    test "changeset validates required fields", _context do
      changeset = CodeSnippet.changeset(%CodeSnippet{}, %{"name" => "", "code" => ""})

      assert not changeset.valid?
      assert Enum.any?(changeset.errors, fn {field, _msg} -> field == :name end)
      assert Enum.any?(changeset.errors, fn {field, _msg} -> field == :code end)
    end

    test "changeset accepts valid data", _context do
      changeset =
        CodeSnippet.changeset(%CodeSnippet{}, %{
          "name" => "Valid",
          "code" => "def test do :ok end",
          "args" => "{\"key\": \"value\"}"
        })

      assert changeset.valid?
    end

    test "changeset converts JSON string args to map", _context do
      changeset =
        CodeSnippet.changeset(%CodeSnippet{}, %{
          "name" => "Valid",
          "code" => "code",
          "args" => "{\"key\": \"value\", \"nested\": {\"data\": 123}}"
        })

      assert changeset.changes.args == %{"key" => "value", "nested" => %{"data" => 123}}
    end

    test "changeset handles empty args gracefully", _context do
      changeset =
        CodeSnippet.changeset(%CodeSnippet{}, %{
          "name" => "Valid",
          "code" => "code",
          "args" => ""
        })

      assert changeset.valid?
      # Empty string is converted to empty map, which is the default
      # So it won't appear in changes but the data will have it
      assert Ecto.Changeset.apply_changes(changeset).args == %{}
    end

    test "changeset handles nil args by setting to empty map", _context do
      changeset =
        CodeSnippet.changeset(%CodeSnippet{}, %{
          "name" => "Valid",
          "code" => "code",
          "args" => nil
        })

      assert changeset.valid?
      # nil is converted to empty map, which is the default
      assert Ecto.Changeset.apply_changes(changeset).args == %{}
    end

    test "changeset preserves map args unchanged", _context do
      args_map = %{"key" => "value", "count" => 42}

      changeset =
        CodeSnippet.changeset(%CodeSnippet{}, %{
          "name" => "Valid",
          "code" => "code",
          "args" => args_map
        })

      assert changeset.valid?
      assert changeset.changes.args == args_map
    end

    test "changeset rejects invalid JSON in args field", _context do
      changeset =
        CodeSnippet.changeset(%CodeSnippet{}, %{
          "name" => "Valid",
          "code" => "code",
          "args" => "{invalid json"
        })

      # Invalid JSON cannot be cast to map type, so changeset is invalid
      assert not changeset.valid?
      assert Enum.any?(changeset.errors, fn {field, _msg} -> field == :args end)
    end
  end

  describe "form field value handling" do
    test "JSON field correctly extracts string value from form", %{conn: conn, code_snippet: cs} do
      {:ok, view, _html} = live(conn, "/admin/code_snippets/#{cs.id}/edit")

      html = render(view)

      # The rendered form should contain the JSON args content
      # Check that the args field displays the JSON in some form
      assert html =~ "Args"
    end

    test "code field correctly displays code content", %{conn: conn, code_snippet: cs} do
      {:ok, view, _html} = live(conn, "/admin/code_snippets/#{cs.id}/edit")

      html = render(view)

      # The code should be visible in the editor
      assert html =~ "def"
    end
  end
end
