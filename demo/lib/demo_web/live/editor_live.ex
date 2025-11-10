defmodule DemoWeb.EditorLive do
  use DemoWeb, :live_view

  alias ExEditor.Document
  alias ExEditor.Editor
  alias ExEditor.Highlighters.JSON
  alias ExEditor.Highlighters.Elixir, as: ElixirHL

  @impl true
  def mount(_params, _session, socket) do
    # Default to JSON content and highlighter
    json_content = """
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

    elixir_content = """
    defmodule MyApp.User do
      @moduledoc \"\"\"
      User module for managing user accounts.
      \"\"\"

      defstruct [:name, :email, :age]

      def create(name, email) when is_binary(name) do
        %__MODULE__{
          name: name,
          email: email,
          age: nil
        }
      end

      def update_age(%__MODULE__{} = user, age) when is_integer(age) do
        %{user | age: age}
      end

      defp validate_email(email) do
        String.contains?(email, "@")
      end
    end
    """

    {:ok, editor} = Editor.new()
    editor = Editor.set_highlighter(editor, JSON)
    {:ok, editor} = Editor.set_content(editor, String.trim(json_content))

    socket =
      assign(socket,
        editor: editor,
        line_count: Document.line_count(editor.document),
        cursor_position: {0, 0},
        selected_language: "json",
        json_content: String.trim(json_content),
        elixir_content: String.trim(elixir_content)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("input-change", %{"value" => new_content}, socket) do
    {:ok, updated_editor} = Editor.set_content(socket.assigns.editor, new_content)

    # Update the stored content for the selected language
    socket =
      case socket.assigns.selected_language do
        "json" -> assign(socket, :json_content, new_content)
        "elixir" -> assign(socket, :elixir_content, new_content)
      end

    socket =
      assign(socket,
        editor: updated_editor,
        line_count: Document.line_count(updated_editor.document)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_cursor", %{"selection_start" => pos, "selection_end" => _}, socket) do
    content = Editor.get_content(socket.assigns.editor)
    {line, col} = calculate_cursor_position(content, pos)
    socket = assign(socket, cursor_position: {line, col})
    {:noreply, socket}
  end

  @impl true
  def handle_event("change_language", %{"language" => language}, socket) do
    # Get the content for the selected language
    content =
      case language do
        "json" -> socket.assigns.json_content
        "elixir" -> socket.assigns.elixir_content
      end

    # Set the appropriate highlighter
    highlighter =
      case language do
        "json" -> JSON
        "elixir" -> ElixirHL
      end

    editor = Editor.set_highlighter(socket.assigns.editor, highlighter)
    {:ok, editor} = Editor.set_content(editor, content)

    socket =
      assign(socket,
        editor: editor,
        selected_language: language,
        line_count: Document.line_count(editor.document)
      )

    {:noreply, socket}
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
    <Layouts.app flash={@flash}>
      <div class="flex h-screen w-screen flex-col bg-base-100 text-base-content">
        <header class="navbar bg-base-300">
          <div class="flex-1">
            <a href="/" class="btn btn-ghost text-xl">ExEditor Demo</a>
          </div>
          <div class="flex-none gap-4">
            <div class="form-control">
              <select
                class="select select-bordered"
                phx-change="change_language"
                name="language"
              >
                <option value="json" selected={@selected_language == "json"}>JSON</option>
                <option value="elixir" selected={@selected_language == "elixir"}>Elixir</option>
              </select>
            </div>
            <ul class="menu menu-horizontal px-1">
              <li>
                <a
                  href="https://github.com/thanos/ex_editor"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  GitHub
                </a>
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
              Line: {elem(@cursor_position, 0) + 1}, Column: {elem(@cursor_position, 1) + 1} | Lines: {@line_count} | Language: {String.upcase(
                @selected_language
              )}
            </div>
          </div>
        </main>
      </div>
    </Layouts.app>
    """
  end
end
