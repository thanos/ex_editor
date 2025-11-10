defmodule DemoWeb.EditorLive do
  use DemoWeb, :live_view
  alias ExEditor.Editor
  alias ExEditor.Highlighters.JSON

  @impl true
  def mount(_params, _session, socket) do
    initial_content = ~s"""
    {
      "name": "ExEditor",
      "version": "0.1.1",
      "description": "A headless code editor for Phoenix LiveView",
      "features": [
        "Real-time editing",
        "Cursor tracking",
        "Syntax highlighting",
        "Plugin system"
      ],
      "config": {
        "theme": "dark",
        "tabSize": 2,
        "lineNumbers": true
      },
      "keywords": ["elixir", "phoenix", "liveview", "editor"],
      "license": "MIT",
      "active": true,
      "downloads": 1250,
      "rating": 4.8
    }
    """

    {:ok, editor} = Editor.new(content: String.trim(initial_content))
    editor = Editor.set_highlighter(editor, JSON)

    {:ok,
     socket
     |> assign(:editor, editor)
     |> assign(:content, Editor.get_content(editor))
     |> assign(:highlighted_content, Editor.get_highlighted_content(editor))
     |> assign(:cursor_line, 1)
     |> assign(:cursor_col, 1)}
  end

  @impl true
  def handle_event("update_content", %{"content" => content}, socket) do
    {:ok, editor} = Editor.set_content(socket.assigns.editor, content)

    {:noreply,
     socket
     |> assign(:editor, editor)
     |> assign(:content, content)
     |> assign(:highlighted_content, Editor.get_highlighted_content(editor))}
  end

  @impl true
  def handle_event("update_cursor", %{"selection_start" => pos, "selection_end" => _}, socket) do
    content = socket.assigns.content
    {line, col} = calculate_cursor_position(content, pos)

    {:noreply,
     socket
     |> assign(:cursor_line, line)
     |> assign(:cursor_col, col)}
  end

  defp calculate_cursor_position(content, position) do
    lines = String.split(content, "\n")

    {line, col} =
      Enum.reduce_while(lines, {0, position}, fn line_text, {line_num, remaining} ->
        line_length = String.length(line_text) + 1

        if remaining < line_length do
          {:halt, {line_num + 1, remaining + 1}}
        else
          {:cont, {line_num + 1, remaining - line_length}}
        end
      end)

    {line, col}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#1e1e1e] text-[#d4d4d4] p-8">
      <div class="max-w-7xl mx-auto">
        <div class="mb-6">
          <h1 class="text-3xl font-bold text-white mb-2">ExEditor Demo</h1>
          <p class="text-[#858585]">
            A headless code editor for Phoenix LiveView with JSON syntax highlighting
          </p>
        </div>

        <div class="mb-4 flex items-center justify-between">
          <div class="inline-block bg-[#007acc] text-white px-3 py-1 rounded text-sm font-mono">
            Ln {@cursor_line}, Col {@cursor_col}
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div>
            <h2 class="text-lg font-semibold mb-2 text-white">Editor</h2>
            <textarea
              id="editor-textarea"
              phx-hook="EditorSync"
              phx-change="update_content"
              class="w-full h-[600px] bg-[#1e1e1e] text-[#d4d4d4] font-mono text-sm p-4 border border-[#3e3e3e] rounded focus:outline-none focus:border-[#007acc] resize-none"
              spellcheck="false"
            >{@content}</textarea>
          </div>

          <div>
            <h2 class="text-lg font-semibold mb-2 text-white">Highlighted Output</h2>
            <div class="w-full h-[600px] bg-[#1e1e1e] text-[#d4d4d4] font-mono text-sm p-4 border border-[#3e3e3e] rounded overflow-auto">
              <pre class="whitespace-pre-wrap"><code>{Phoenix.HTML.raw(@highlighted_content)}</code></pre>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
