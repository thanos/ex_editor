defmodule DemoWeb.EditorLive do
  @moduledoc """
  Demo LiveView for ExEditor - shows the editor in action
  """
  use DemoWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    initial_content = """
    defmodule Example do
      @moduledoc \"\"\"
      This is an example Elixir module to demonstrate
      the ExEditor in action.
      \"\"\"

      def hello(name) do
        "Hello, \#{name}!"
      end

      def add(a, b) when is_number(a) and is_number(b) do
        a + b
      end

      defp private_function do
        :ok
      end
    end
    """

    editor = ExEditor.Editor.new(content: initial_content)

    {:ok,
     socket
     |> assign(:editor, editor)
     |> assign(:cursor_line, 1)
     |> assign(:cursor_col, 1)}
  end

  @impl true
  def handle_event("update_content", %{"content" => content}, socket) do
    case ExEditor.Editor.set_content(socket.assigns.editor, content) do
      {:ok, updated_editor} ->
        {:noreply, assign(socket, :editor, updated_editor)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_cursor", params, socket) do
    %{"selection_start" => start_pos} = params
    content = ExEditor.Editor.get_content(socket.assigns.editor)

    # Calculate line and column from cursor position
    {line, col} = calculate_cursor_position(content, start_pos)

    {:noreply,
     socket
     |> assign(:cursor_line, line)
     |> assign(:cursor_col, col)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#1e1e1e] text-[#d4d4d4]">
      <div class="container mx-auto px-4 py-8">
        <h1 class="text-3xl font-bold mb-6 text-white">ExEditor Demo</h1>

        <div class="mb-4 flex items-center justify-between">
          <div class="text-sm text-gray-400">
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
              class="ex-editor-textarea font-mono text-sm w-full h-[600px] p-4 bg-[#1e1e1e] text-[#d4d4d4] border border-[#3e3e3e] rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              spellcheck="false"
            ><%= ExEditor.Editor.get_content(@editor) %></textarea>
          </div>

          <div>
            <h2 class="text-lg font-semibold mb-2 text-white">Raw Content</h2>
            <pre class="font-mono text-sm w-full h-[600px] p-4 bg-[#252525] text-[#d4d4d4] border border-[#3e3e3e] rounded-lg overflow-auto"><%= ExEditor.Editor.get_content(@editor) %></pre>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Private helpers

  defp calculate_cursor_position(content, position) do
    lines = String.split(content, "\n")

    {line, col, _} =
      Enum.reduce_while(lines, {1, 1, 0}, fn line_text, {current_line, _col, char_count} ->
        line_length = String.length(line_text) + 1

        if char_count + line_length > position do
          col = position - char_count + 1
          {:halt, {current_line, col, char_count}}
        else
          {:cont, {current_line + 1, 1, char_count + line_length}}
        end
      end)

    {line, col}
  end
end
