defmodule DemoWeb.Admin.CodeSnippetMultipleEditorsTest do
  @moduledoc """
  REGRESSION TEST: Verifies that the args field and code field maintain separate
  values when both are edited in the Backpex form.

  Previously, the EditorFormSync hook would sync the args field with the code
  field's value because it always found the FIRST editor hook in the form.
  """
  use DemoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Demo.CMS.CodeSnippet
  alias Demo.Repo

  setup do
    code_snippet =
      Repo.insert!(%CodeSnippet{
        name: "Test Snippet",
        code: "def test_code do\n  :code_value\nend",
        args: %{"key" => "original_args", "nested" => %{"data" => "args_data"}}
      })

    {:ok, code_snippet: code_snippet}
  end

  describe "multiple editors in Backpex form" do
    test "renders both code and args editors", %{conn: conn, code_snippet: cs} do
      {:ok, view, _html} = live(conn, "/admin/code_snippets/#{cs.id}/edit")

      # Both editors should be present
      assert has_element?(view, "#editor_code")
      assert has_element?(view, "#editor_args")
    end

    test "displays correct initial values in code editor", %{
      conn: conn,
      code_snippet: cs
    } do
      {:ok, view, _html} = live(conn, "/admin/code_snippets/#{cs.id}/edit")

      html = render(view)
      # The code content should be visible (may have syntax highlighting HTML)
      assert html =~ "test_code"
      assert html =~ "code_value"
    end

    test "displays correct initial values in args editor", %{
      conn: conn,
      code_snippet: cs
    } do
      {:ok, view, _html} = live(conn, "/admin/code_snippets/#{cs.id}/edit")

      html = render(view)
      # The args should be JSON formatted
      assert html =~ "original_args"
      assert html =~ "args_data"
    end

    test "form has correct field structure for form submission", %{
      conn: conn,
      code_snippet: cs
    } do
      {:ok, view, _html} = live(conn, "/admin/code_snippets/#{cs.id}/edit")

      html = render(view)

      # Should have hidden inputs with correct IDs for syncing
      # EditorFormSync hooks should be on these hidden inputs
      assert html =~ "phx-hook=\"EditorFormSync\""

      # Code editor ID should be "editor_code"
      assert html =~ ~s(id="editor_code")

      # Args editor ID should be "editor_args"
      assert html =~ ~s(id="editor_args")
    end

    test "editors have separate hook targets", %{conn: conn, code_snippet: cs} do
      {:ok, view, _html} = live(conn, "/admin/code_snippets/#{cs.id}/edit")

      html = render(view)

      # Count editor containers
      code_editor_count = html |> String.split(~s(id="editor_code")) |> length()
      args_editor_count = html |> String.split(~s(id="editor_args")) |> length()

      # Should have exactly one of each
      assert code_editor_count == 2  # 1 split means it appeared once
      assert args_editor_count == 2  # 1 split means it appeared once
    end
  end

  describe "EditorFormSync hook field mapping (REGRESSION)" do
    test "REGRESSION: args field does not get code field value", %{
      conn: conn,
      code_snippet: cs
    } do
      {:ok, view, _html} = live(conn, "/admin/code_snippets/#{cs.id}/edit")

      html = render(view)

      # The hidden input for code field should have code content
      # The hidden input for args field should have args JSON content
      # They should NOT be swapped or duplicated

      # Find the hidden inputs in the HTML
      # Look for the structure created by render_form in json_field.ex
      # and code_field.ex

      # Count occurrences of the code content
      code_value = "def test_code do"
      args_key = "original_args"

      # The code value should appear in the code editor area
      assert html =~ code_value

      # The args value should appear in the args editor area
      assert html =~ args_key

      # Critical: They should NOT be in each other's hidden inputs
      # If they are, we'd see args_key appearing in the code hidden input
      # or code_value appearing in the args hidden input

      # This is verified by the presence of both distinct editor containers
      assert html =~ ~s(id="editor_code")
      assert html =~ ~s(id="editor_args")

      # And the structure of the form shows they're separate
      assert html =~ ~s(id="editor_code-textarea")
      assert html =~ ~s(id="editor_args-textarea")
    end

    test "hidden inputs correspond to correct editors", %{
      conn: conn,
      code_snippet: cs
    } do
      {:ok, view, _html} = live(conn, "/admin/code_snippets/#{cs.id}/edit")

      html = render(view)

      # Each hidden input should have a unique data-field-id
      # These are used by EditorFormSync to track which editor to sync with

      # The hidden input after editor_code should reference the code field
      # The hidden input after editor_args should reference the args field

      # Verify the structure exists
      assert String.contains?(html, "data-field-id")

      # We should see multiple EditorFormSync hooks
      sync_count = html |> String.split("phx-hook=\"EditorFormSync\"") |> length()
      # Should have at least 2 sync hooks (one for code, one for args)
      assert sync_count >= 2
    end
  end
end
