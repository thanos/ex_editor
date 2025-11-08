defmodule ExEditorWeb.EditorLive do
  @moduledoc """
  LiveView for the ExEditor code editor demo.

  Demonstrates the headless editor with:
  - Shadow textarea for input
  - Line numbering overlay
  - Real-time document updates
  """

  use ExEditorWeb, :live_view

  alias ExEditor.Editor

  @impl true
  def mount(_params, _session, socket) do
    # Initialize with sample JSON content
    initial_content = """
    {
      "name": "ExEditor",
      "version": "0.1.0",
      "description": "Headless code editor for Phoenix LiveView",
      "features": [
        "Line numbering",
        "Plugin system",
        "Real-time updates",
        "Accessible shadow textarea"
      ],
      "tech_stack": {
        "backend": "Elixir + Phoenix",
        "frontend": "LiveView",
        "styling": "TailwindCSS"
      }
    }
    """

    editor = Editor.new(content: String.trim(initial_content))

    {:ok,
     socket
     |> assign(:editor, editor)
     |> assign(:show_line_numbers, true)
     |> assign(:page_title, "ExEditor Demo")}
  end

  @impl true
  def handle_event("update_content", %{"content" => content}, socket) do
    case Editor.set_content(socket.assigns.editor, content) do
      {:ok, updated_editor} ->
        {:noreply, assign(socket, :editor, updated_editor)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_line_numbers", _params, socket) do
    {:noreply, assign(socket, :show_line_numbers, not socket.assigns.show_line_numbers)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="min-h-screen bg-[#1e1e1e] py-8 px-4">
        <div class="max-w-5xl mx-auto">
          <%!-- Header --%>
          <div class="mb-6 flex items-center justify-between">
            <div>
              <h1 class="text-3xl font-bold text-[#d4d4d4] mb-2">ExEditor Demo</h1>
              <p class="text-[#858585]">Headless code editor with shadow textarea architecture</p>
            </div>
            <button
              phx-click="toggle_line_numbers"
              class="px-4 py-2 bg-[#0e639c] hover:bg-[#1177bb] text-white rounded-lg transition-colors"
            >
              {if @show_line_numbers, do: "Hide", else: "Show"} Line Numbers
            </button>
          </div>

          <%!-- Editor Container --%>
          <div class="bg-[#252526] rounded-lg shadow-2xl overflow-hidden border border-[#3e3e42]">
            <%!-- Editor Header --%>
            <div class="bg-[#2d2d30] px-4 py-2 border-b border-[#3e3e42] flex items-center justify-between">
              <div class="flex items-center gap-2">
                <div class="w-3 h-3 rounded-full bg-[#ff5f56]"></div>
                <div class="w-3 h-3 rounded-full bg-[#ffbd2e]"></div>
                <div class="w-3 h-3 rounded-full bg-[#27c93f]"></div>
              </div>
              <span class="text-[#858585] text-sm font-mono">example.json</span>
              <div class="text-[#858585] text-xs">
                Lines: {Document.line_count(@editor.document)}
              </div>
            </div>

            <%!-- Editor Content --%>
            <div class="relative font-mono text-sm">
              <div class="flex">
                <%!-- Line Numbers Gutter --%>
                <%= if @show_line_numbers do %>
                  <div class="bg-[#1e1e1e] text-[#858585] text-right py-4 px-3 select-none border-r border-[#3e3e42] min-w-[3rem]">
                    <%= for line_num <- 1..Document.line_count(@editor.document) do %>
                      <div class="leading-6 h-6">{line_num}</div>
                    <% end %>
                  </div>
                <% end %>

                <%!-- Editor Content Area --%>
                <div class="flex-1 relative">
                  <%!-- Shadow Textarea (hidden but accessible) --%>
                  <textarea
                    id="editor-textarea"
                    phx-hook="EditorSync"
                    phx-change="update_content"
                    name="content"
                    class="absolute inset-0 w-full h-full py-4 px-4 bg-transparent text-transparent caret-[#d4d4d4] resize-none outline-none font-mono text-sm leading-6 z-10"
                    spellcheck="false"
                    autocomplete="off"
                  ><%= Editor.get_content(@editor) %></textarea>

                  <%!-- Rendered Content Overlay --%>
                  <div class="py-4 px-4 text-[#d4d4d4] pointer-events-none relative z-0" phx-no-format>
    <%= for line <- @editor.document.lines do %>
    <div class="leading-6 h-6 whitespace-pre"><%= if line == "", do: " ", else: line %></div>
    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <%!-- Info Panel --%>
          <div class="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="bg-[#252526] rounded-lg p-4 border border-[#3e3e42]">
              <div class="text-[#4ec9b0] text-xl mb-2">🎯</div>
              <h3 class="text-[#d4d4d4] font-semibold mb-1">Shadow Textarea</h3>
              <p class="text-[#858585] text-sm">
                Hidden textarea handles all input for accessibility
              </p>
            </div>

            <div class="bg-[#252526] rounded-lg p-4 border border-[#3e3e42]">
              <div class="text-[#ce9178] text-xl mb-2">📊</div>
              <h3 class="text-[#d4d4d4] font-semibold mb-1">Line Numbering</h3>
              <p class="text-[#858585] text-sm">Dynamic line numbers synced with content</p>
            </div>

            <div class="bg-[#252526] rounded-lg p-4 border border-[#3e3e42]">
              <div class="text-[#9cdcfe] text-xl mb-2">⚡</div>
              <h3 class="text-[#d4d4d4] font-semibold mb-1">Real-time Updates</h3>
              <p class="text-[#858585] text-sm">LiveView syncs state instantly</p>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
