defmodule ExEditor.HighlighterTest do
  use ExUnit.Case, async: true

  # Test implementation of Highlighter behaviour
  defmodule TestHighlighter do
    @behaviour ExEditor.Highlighter

    @impl true
    def highlight(text) do
      text
      |> String.split(" ")
      |> Enum.map_join(" ", fn word ->
        if word in ["def", "if", "do"] do
          ~s(<span class="hl-keyword">#{word}</span>)
        else
          word
        end
      end)
    end

    @impl true
    def name, do: "Test Language"
  end

  describe "Highlighter behaviour" do
    test "highlight/1 callback returns HTML string" do
      result = TestHighlighter.highlight("def hello")
      assert is_binary(result)
      assert String.contains?(result, "<span")
      assert String.contains?(result, "hl-keyword")
    end

    test "name/0 callback returns language name" do
      name = TestHighlighter.name()
      assert name == "Test Language"
      assert is_binary(name)
    end

    test "highlight handles multiple keywords" do
      result = TestHighlighter.highlight("def hello if true do end")
      assert String.contains?(result, ~s(<span class="hl-keyword">def</span>))
      assert String.contains?(result, ~s(<span class="hl-keyword">if</span>))
      assert String.contains?(result, ~s(<span class="hl-keyword">do</span>))
    end
  end

  describe "Built-in Elixir highlighter" do
    test "Elixir highlighter returns expected name" do
      assert ExEditor.Highlighters.Elixir.name() == "Elixir"
    end

    test "Elixir highlighter produces HTML output" do
      result = ExEditor.Highlighters.Elixir.highlight("def hello, do: :world")
      assert is_binary(result)
      assert String.contains?(result, "<span")
      assert String.contains?(result, "hl-")
    end

    test "Elixir highlighter highlights keywords" do
      result = ExEditor.Highlighters.Elixir.highlight("def hello do end")
      assert String.contains?(result, ~s(class="hl-keyword"))
    end

    test "Elixir highlighter highlights atoms" do
      result = ExEditor.Highlighters.Elixir.highlight(":ok :error")
      assert String.contains?(result, ~s(class="hl-key"))
    end

    test "Elixir highlighter handles strings" do
      result = ExEditor.Highlighters.Elixir.highlight(~s("hello"))
      assert String.contains?(result, ~s(class="hl-string"))
    end

    test "Elixir highlighter handles numbers" do
      result = ExEditor.Highlighters.Elixir.highlight("42 3.14")
      assert String.contains?(result, ~s(class="hl-number"))
    end

    test "Elixir highlighter handles comments" do
      result = ExEditor.Highlighters.Elixir.highlight("# comment")
      assert String.contains?(result, ~s(class="hl-comment"))
    end

    test "Elixir highlighter handles heredocs" do
      text = ~S("""
      multi
      line
      """)
      result = ExEditor.Highlighters.Elixir.highlight(text)
      assert String.contains?(result, ~s(class="hl-string"))
    end
  end

  describe "Built-in JSON highlighter" do
    test "JSON highlighter returns expected name" do
      assert ExEditor.Highlighters.JSON.name() == "JSON"
    end

    test "JSON highlighter produces HTML output" do
      result = ExEditor.Highlighters.JSON.highlight(~s({"key": "value"}))
      assert is_binary(result)
      assert String.contains?(result, "<span")
    end

    test "JSON highlighter highlights strings" do
      result = ExEditor.Highlighters.JSON.highlight(~s({"name": "Alice"}))
      assert String.contains?(result, ~s(class="hl-string"))
    end

    test "JSON highlighter highlights numbers" do
      result = ExEditor.Highlighters.JSON.highlight(~s({"count": 42}))
      assert String.contains?(result, ~s(class="hl-number"))
    end

    test "JSON highlighter highlights booleans" do
      result = ExEditor.Highlighters.JSON.highlight(~s({"active": true}))
      assert String.contains?(result, ~s(class="hl-boolean"))
    end
  end
end
