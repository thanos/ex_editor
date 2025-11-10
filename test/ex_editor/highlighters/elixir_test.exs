defmodule ExEditor.Highlighters.ElixirTest do
  use ExUnit.Case, async: true

  alias ExEditor.Highlighters.Elixir, as: ElixirHL

  describe "name/0" do
    test "returns Elixir" do
      assert ElixirHL.name() == "Elixir"
    end
  end

  describe "highlight/1" do
    test "highlights simple function definition" do
      code = "def hello(name), do: name"
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-keyword">def</span>)
      assert result =~ ~s(<span class="hl-function">hello</span>)
      assert result =~ ~s(<span class="hl-variable">name</span>)
      assert result =~ ~s(<span class="hl-keyword">do</span>)
    end

    test "highlights module definition" do
      code = "defmodule MyApp.User do\nend"
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-keyword">defmodule</span>)
      assert result =~ ~s(<span class="hl-module">MyApp.User</span>)
      assert result =~ ~s(<span class="hl-keyword">do</span>)
      assert result =~ ~s(<span class="hl-keyword">end</span>)
    end

    test "highlights atoms" do
      code = ":ok :error :atom_name"
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-key">:ok</span>)
      assert result =~ ~s(<span class="hl-key">:error</span>)
      assert result =~ ~s(<span class="hl-key">:atom_name</span>)
    end

    test "highlights quoted atoms" do
      code = ~s(:"quoted atom")
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-key">:&quot;quoted atom&quot;</span>)
    end

    test "highlights double quoted strings" do
      code = ~s("hello world")
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-string">&quot;hello world&quot;</span>)
    end

    test "highlights single quoted strings" do
      code = ~s('hello')
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-string">&#39;hello&#39;</span>)
    end

    test "highlights escaped characters in strings" do
      code = ~s("hello \\"world\\"")
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-string">&quot;hello \\&quot;world\\&quot;&quot;</span>)
    end

    test "highlights numbers" do
      code = "42 3.14 -5 0x1F 0o17 0b1010"
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-number">42</span>)
      assert result =~ ~s(<span class="hl-number">3.14</span>)
      assert result =~ ~s(<span class="hl-number">-5</span>)
      assert result =~ ~s(<span class="hl-number">0x1F</span>)
      assert result =~ ~s(<span class="hl-number">0o17</span>)
      assert result =~ ~s(<span class="hl-number">0b1010</span>)
    end

    test "highlights booleans" do
      code = "true false"
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-boolean">true</span>)
      assert result =~ ~s(<span class="hl-boolean">false</span>)
    end

    test "highlights nil" do
      code = "nil"
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-null">nil</span>)
    end

    test "highlights comments" do
      code = "# This is a comment\ncode"
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-comment"># This is a comment</span>)
    end

    test "highlights operators" do
      code = "|> ++ -- === == != <= >= <> :: -> <-"
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-operator">|&gt;</span>)
      assert result =~ ~s(<span class="hl-operator">++</span>)
      assert result =~ ~s(<span class="hl-operator">--</span>)
      assert result =~ ~s(<span class="hl-operator">===</span>)
      assert result =~ ~s(<span class="hl-operator">==</span>)
      assert result =~ ~s(<span class="hl-operator">!=</span>)
      assert result =~ ~s(<span class="hl-operator">&lt;=</span>)
      assert result =~ ~s(<span class="hl-operator">&gt;=</span>)
      assert result =~ ~s(<span class="hl-operator">&lt;&gt;</span>)
      assert result =~ ~s(<span class="hl-operator">::</span>)
      assert result =~ ~s(<span class="hl-operator">-&gt;</span>)
      assert result =~ ~s(<span class="hl-operator">&lt;-</span>)
    end

    test "highlights punctuation" do
      code = "( ) [ ] { } , . ;"
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-punctuation">(</span>)
      assert result =~ ~s|<span class="hl-punctuation">)</span>|
      assert result =~ ~s(<span class="hl-punctuation">[</span>)
      assert result =~ ~s(<span class="hl-punctuation">]</span>)
      assert result =~ ~s(<span class="hl-punctuation">{</span>)
      assert result =~ ~s(<span class="hl-punctuation">}</span>)
      assert result =~ ~s(<span class="hl-punctuation">,</span>)
      assert result =~ ~s(<span class="hl-punctuation">.</span>)
    end

    test "highlights function calls" do
      code = "hello(world)"
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-function">hello</span>)
      assert result =~ ~s(<span class="hl-punctuation">(</span>)
      assert result =~ ~s(<span class="hl-variable">world</span>)
    end

    test "highlights module attributes" do
      code = "@moduledoc @doc @spec"
      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-variable">@moduledoc</span>)
      assert result =~ ~s(<span class="hl-variable">@doc</span>)
      assert result =~ ~s(<span class="hl-variable">@spec</span>)
    end

    test "highlights sigils" do
      code = ~s[~s(hello) ~r/pattern/]
      result = ElixirHL.highlight(code)

      # FIX: Changed ~s() delimiters to ~s|| to avoid conflict with nested ~s(hello)
      assert result =~ ~s|<span class="hl-string">~s(hello)</span>|
      assert result =~ ~s|<span class="hl-string">~r/pattern/</span>|
    end

    test "highlights complex code" do
      code = """
      defmodule MyApp.User do
        @moduledoc "User module"

        def create(name, age) when is_binary(name) do
          %{name: name, age: age}
        end
      end
      """

      result = ElixirHL.highlight(code)

      assert result =~ ~s(<span class="hl-keyword">defmodule</span>)
      assert result =~ ~s(<span class="hl-module">MyApp.User</span>)
      assert result =~ ~s(<span class="hl-variable">@moduledoc</span>)
      assert result =~ ~s(<span class="hl-string">&quot;User module&quot;</span>)
      assert result =~ ~s(<span class="hl-keyword">def</span>)
      assert result =~ ~s(<span class="hl-function">create</span>)
      assert result =~ ~s(<span class="hl-keyword">when</span>)
      assert result =~ ~s(<span class="hl-function">is_binary</span>)
    end

    test "preserves whitespace" do
      code = "def  hello\n  do"
      result = ElixirHL.highlight(code)

      assert result =~ "  "
      assert result =~ "\n"
    end

    test "escapes HTML in code" do
      code = ~s(<div>)
      result = ElixirHL.highlight(code)

      assert result =~ "&lt;div&gt;"
      refute result =~ "<div>"
    end
  end
end
