defmodule DemoWeb.EditorLive do
  use DemoWeb, :live_view

  alias ExEditor.Document
  alias ExEditor.Editor
  alias ExEditor.Highlighters.JSON

  @impl true
  def mount(_params, _session, socket) do
    initial_content = """
    {
      "name": "John Doe",
      "age": 30,
      "isStudent": false,
      "courses": ["Math", "Science"],
      "address": {
        "street": "123 Main St",
        "city": "Anytown"
      },
      "grades": null
    }
    """

    {:ok, editor} = Editor.new()
    editor = Editor.set_highlighter(editor, JSON)
    {:ok, editor} = Editor.set_content(editor, String.trim(initial_content))

    socket =
      assign(socket,
        editor: editor,
        line_count: Document.line_count(editor.document),
        cursor_position: {0, 0}
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("input-change", %{"value" => new_content}, socket) do
    {:ok, updated_editor} = Editor.set_content(socket.assigns.editor, new_content)

    socket =
      assign(socket,
        editor: updated_editor,
        line_count: Document.line_count(updated_editor.document)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("cursor-change", %{"line" => line, "column" => column}, socket) do
    socket = assign(socket, cursor_position: {line, column})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex h-screen w-screen flex-col bg-base-100 text-base-content">
        <header class="navbar bg-base-300">
          <div class="flex-1">
            <a href="/" class="btn btn-ghost text-xl">ExEditor Demo</a>
          </div>
          <div class="flex-none">
            <ul class="menu menu-horizontal px-1">
              <li>
                <a
                  href="https://github.com/thanos/ex_editor"
                  target="_blank"
                  rel="noopener noreferrer"
                  >GitHub</a
                >
              </li>
            </ul>
          </div>
        </header>

        <main class="flex flex-1 overflow-hidden">
          <div class="flex h-full w-full flex-col">
            <div class="flex-1 overflow-auto p-4 font-mono text-sm">
              <pre
                id="editor"
                class="relative h-full w-full whitespace-pre-wrap outline-none"
                phx-update="ignore"
                phx-hook="EditorSync"
                data-content={Editor.get_content(@editor)}
              ><%= raw Editor.get_highlighted_content(@editor) %></pre>
            </div>
            <div class="border-t border-base-200 bg-base-300 p-2 text-xs">
              Line: <%= elem(@cursor_position, 0) + 1 %>, Column: <%= elem(@cursor_position, 1) + 1 %> | Lines: <%= @line_count %>
            </div>
          </div>
        </main>
      </div>
    </Layouts.app>
    """
  end
end
