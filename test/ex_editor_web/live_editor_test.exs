defmodule ExEditorWeb.LiveEditorTest do
  use ExUnit.Case, async: true

  describe "ExEditorWeb.LiveEditor component" do
    test "component module exists" do
      assert is_atom(ExEditorWeb.LiveEditor)
    end
  end

  describe "Language support" do
    test "Elixir highlighter exists and is loadable" do
      assert ExEditor.Highlighters.Elixir.name() == "Elixir"
    end

    test "JSON highlighter exists and is loadable" do
      assert ExEditor.Highlighters.JSON.name() == "JSON"
    end
  end
end
