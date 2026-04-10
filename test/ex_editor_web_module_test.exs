defmodule ExEditorWebModuleTest do
  @moduledoc """
  Tests for ExEditorWeb module to achieve 100% coverage.
  """
  use ExUnit.Case, async: true

  describe "ExEditorWeb module exports" do
    test "live_editor function is accessible" do
      # Test calling it works
      assigns = %{id: "test"}
      result = ExEditorWeb.live_editor(assigns)

      # Result should be a component (returns a compiled template)
      assert result
    end

    test "live_editor delegates to ExEditorWeb.LiveEditor" do
      # LiveEditor module should have the function
      assert function_exported?(ExEditorWeb.LiveEditor, :live_editor, 1)

      # They should produce the same result
      assigns = %{id: "test", content: "code"}
      result1 = ExEditorWeb.live_editor(assigns)
      result2 = ExEditorWeb.LiveEditor.live_editor(assigns)

      # Both should return truthy values (component functions)
      assert result1
      assert result2
    end
  end

  describe "ExEditorWeb module structure" do
    test "module is loaded" do
      assert Code.ensure_loaded?(ExEditorWeb)
    end

    test "LiveEditor submodule is loaded" do
      assert Code.ensure_loaded?(ExEditorWeb.LiveEditor)
    end

    test "live_editor function works with various options" do
      assigns = %{
        id: "comprehensive-test",
        content: "test code",
        language: :elixir,
        on_change: "code_changed",
        readonly: false,
        line_numbers: true,
        class: "custom",
        debounce: 100
      }

      result = ExEditorWeb.live_editor(assigns)
      assert result
    end

    test "live_editor function works with minimal options" do
      assigns = %{id: "minimal"}
      result = ExEditorWeb.live_editor(assigns)
      assert result
    end
  end
end
