defmodule ExEditor.Highlighters.JSONTest do
  use ExUnit.Case, async: true

  alias ExEditor.Highlighters.JSON

  describe "name/0" do
    test "returns JSON" do
      assert JSON.name() == "JSON"
    end
  end

  describe "highlight/1" do
    test "highlights simple object" do
      json = ~s({"name": "John"})
      result = JSON.highlight(json)

      assert result =~ ~s(<span class="hl-punctuation">{</span>)
      assert result =~ ~s(<span class="hl-key">"name"</span>)
      assert result =~ ~s(<span class="hl-punctuation">:</span>)
      assert result =~ ~s(<span class="hl-string">"John"</span>)
      assert result =~ ~s(<span class="hl-punctuation">}</span>)
    end

    test "highlights multiple keys" do
      json = ~s({"name": "John", "age": 30})
      result = JSON.highlight(json)

      assert result =~ ~s(<span class="hl-key">"name"</span>)
      assert result =~ ~s(<span class="hl-key">"age"</span>)
      assert result =~ ~s(<span class="hl-punctuation">,</span>)
    end

    test "highlights numbers" do
      json = ~s({"age": 30, "price": 19.99, "count": -5})
      result = JSON.highlight(json)

      assert result =~ ~s(<span class="hl-number">30</span>)
      assert result =~ ~s(<span class="hl-number">19.99</span>)
      assert result =~ ~s(<span class="hl-number">-5</span>)
    end

    test "highlights booleans" do
      json = ~s({"active": true, "deleted": false})
      result = JSON.highlight(json)

      assert result =~ ~s(<span class="hl-boolean">true</span>)
      assert result =~ ~s(<span class="hl-boolean">false</span>)
    end

    test "highlights null" do
      json = ~s({"value": null})
      result = JSON.highlight(json)

      assert result =~ ~s(<span class="hl-null">null</span>)
    end

    test "highlights arrays" do
      json = ~s([1, 2, 3])
      result = JSON.highlight(json)

      assert result =~ ~s(<span class="hl-punctuation">[</span>)
      assert result =~ ~s(<span class="hl-number">1</span>)
      assert result =~ ~s(<span class="hl-number">2</span>)
      assert result =~ ~s(<span class="hl-number">3</span>)
      assert result =~ ~s(<span class="hl-punctuation">]</span>)
    end

    test "highlights nested objects" do
      json = ~s({"user": {"name": "John"}})
      result = JSON.highlight(json)

      assert result =~ ~s(<span class="hl-key">"user"</span>)
      assert result =~ ~s(<span class="hl-key">"name"</span>)
    end

    test "escapes HTML characters in strings" do
      json = ~s({"html": "<div>"})
      result = JSON.highlight(json)

      assert result =~ "&lt;div&gt;"
      refute result =~ "<div>"
    end

    test "handles escaped quotes in strings" do
      json = ~s({"quote": "He said \\"hello\\""})
      result = JSON.highlight(json)

      assert result =~ ~s(<span class="hl-string">"He said \\"hello\\""</span>)
    end

    test "preserves whitespace" do
      json = """
      {
        "name": "John"
      }
      """

      result = JSON.highlight(json)

      assert result =~ "\n"
      assert result =~ "  "
    end

    test "highlights complex nested structure" do
      json = ~s({"users": [{"name": "John", "active": true}, {"name": "Jane", "active": false}]})
      result = JSON.highlight(json)

      assert result =~ ~s(<span class="hl-key">"users"</span>)
      assert result =~ ~s(<span class="hl-string">"John"</span>)
      assert result =~ ~s(<span class="hl-string">"Jane"</span>)
      assert result =~ ~s(<span class="hl-boolean">true</span>)
      assert result =~ ~s(<span class="hl-boolean">false</span>)
    end

    test "highlights scientific notation" do
      json = ~s({"value": 1.5e10})
      result = JSON.highlight(json)

      assert result =~ ~s(<span class="hl-number">1.5e10</span>)
    end
  end
end
