defmodule DemoWeb.EditorLive do
  @moduledoc """
  Demo LiveView for ExEditor - showcases the LiveEditor component.
  """
  use DemoWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    initial_content = """
    defmodule Example do
      @moduledoc \"""
      This is an example Elixir module to demonstrate
      the ExEditor in action.
      \"""

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

    {:ok, assign(socket, :code, initial_content)}
  end

  @impl true
  def handle_info({:code_changed, %{content: new_code}}, socket) do
    {:noreply, assign(socket, :code, new_code)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#1e1e1e] text-[#d4d4d4]">
      <div class="container mx-auto px-4 py-8">
        <h1 class="text-3xl font-bold mb-6 text-white">ExEditor Demo</h1>
        <%= if admin_enabled?() do %>
          <a href="/admin" class="text-blue-400 hover:text-blue-300 mb-4 inline-block">
            Backpex Admin
          </a>
        <% end %>

        <div class="grid grid-cols-2 gap-4 h-[600px]">
          <!-- Editor -->
          <div class="border border-[#3e3e3e] rounded-lg overflow-hidden">
            <.live_component
              module={ExEditorWeb.LiveEditor}
              id="elixir-editor"
              content={@code}
              language={:elixir}
              on_change="code_changed"
            />
          </div>

          <!-- Raw Content Preview -->
          <div class="flex flex-col">
            <h2 class="text-lg font-semibold mb-2 text-white">Raw Content (Preview)</h2>
            <pre class="font-mono text-sm p-4 bg-[#252525] rounded-lg overflow-auto flex-1 border border-[#3e3e3e]"><%= @code %></pre>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp admin_enabled?, do: System.get_env("SKIP_MIGRATIONS") != "true"
end
