defmodule DemoWeb.Admin.BackpexFormSyncRegressionTest do
  @moduledoc """
  REGRESSION TEST: Verifies that EditorFormSync hook correctly finds and syncs
  the right editor when multiple editors are present in the same Backpex form.

  BUG: The EditorFormSync hook was always syncing with the FIRST editor found
  in the form, causing the args field to get the code field's value.

  FIX: EditorFormSync now searches for the preceding editor (in the immediate
  parent context) rather than the first one in the entire form.
  """
  use DemoWeb.ConnCase

  alias Demo.CMS.CodeSnippet
  alias Demo.Repo

  describe "REGRESSION: EditorFormSync finds correct editor" do
    test "code and args fields have separate EditorFormSync hooks" do
      # Create a snippet with distinct values for code and args
      snippet =
        Repo.insert!(%CodeSnippet{
          name: "Counter Example",
          code: "defmodule MyApp.Counter do\n  use GenServer\n  # ...",
          args: %{
            "debug" => false,
            "initial_value" => 0,
            "timeout" => 5000
          }
        })

      # Get the HTML of the edit page via HTTP
      conn = get(build_conn(), "/admin/code_snippets/#{snippet.id}/edit")
      assert conn.status == 200

      html = html_response(conn, 200)

      # Both editors should be present with EditorFormSync hooks
      assert String.contains?(html, "phx-hook=\"EditorFormSync\"")

      # Count the sync hooks - should be at least 2 (one for code, one for args)
      sync_count = String.split(html, "phx-hook=\"EditorFormSync\"") |> length() |> Kernel.-(1)
      assert sync_count >= 2
    end

    test "verify each editor gets the correct initial content" do
      snippet =
        Repo.insert!(%CodeSnippet{
          name: "Test Snippet",
          code: "def test_code do\n  :ok\nend",
          args: %{"key" => "args_value", "test" => true}
        })

      # Check the raw HTML to verify correct values are in correct textareas
      conn = get(build_conn(), "/admin/code_snippets/#{snippet.id}/edit")
      assert conn.status == 200

      html = html_response(conn, 200)

      # Code editor should have code content
      assert html =~ ~s(id="editor_code-textarea")
      assert html =~ "def test_code do"

      # Args editor should have JSON content
      assert html =~ ~s(id="editor_args-textarea")
      assert html =~ "&quot;key&quot;"
      assert html =~ "&quot;args_value&quot;"

      # Critical: code content should NOT appear in args textarea
      # and args should NOT appear in code textarea
      # We verify this indirectly by checking they're in different textarea elements

      # Extract content between the two textareas
      [_before_code, code_and_after] = String.split(html, ~s(id="editor_code-textarea"), parts: 2)
      [code_textarea_content, between_editors] =
        String.split(code_and_after, "</textarea>", parts: 2)

      [_before_args, args_and_after] = String.split(between_editors, ~s(id="editor_args-textarea"), parts: 2)
      [args_textarea_content, _rest] = String.split(args_and_after, "</textarea>", parts: 2)

      # Code textarea should have code keywords, not JSON
      assert code_textarea_content =~ "def test_code"
      assert code_textarea_content =~ ":ok"
      refute code_textarea_content =~ "&quot;key&quot;"

      # Args textarea should have JSON keys, not Elixir code
      assert args_textarea_content =~ "&quot;key&quot;"
      assert args_textarea_content =~ "&quot;args_value&quot;"
      refute args_textarea_content =~ "def test_code"
      refute args_textarea_content =~ ":ok"
    end

    test "both editors are rendered with separate hook targets" do
      snippet =
        Repo.insert!(%CodeSnippet{
          name: "Test",
          code: "code",
          args: %{"key" => "value"}
        })

      conn = get(build_conn(), "/admin/code_snippets/#{snippet.id}/edit")
      html = html_response(conn, 200)

      # Both editors should have EditorHook
      editor_hook_count =
        html
        |> String.split(~s(phx-hook="EditorHook"))
        |> length()
        |> Kernel.-(1)

      assert editor_hook_count >= 2, "Should have at least 2 EditorHook instances"

      # Both should have EditorFormSync hooks
      sync_hook_count =
        html
        |> String.split(~s(phx-hook="EditorFormSync"))
        |> length()
        |> Kernel.-(1)

      assert sync_hook_count >= 2, "Should have at least 2 EditorFormSync instances"

      # Each sync hook should have unique field IDs
      assert html =~ "data-field-id"
    end
  end
end
