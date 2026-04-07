defmodule ExEditorWeb.LiveEditor do
  @moduledoc """
  A LiveView component for displaying an editable code editor with syntax highlighting.

  This component implements a "double-buffer" technique where an invisible textarea
  handles user input while a visible highlighted layer displays the syntax-highlighted
  code with line numbers and a fake cursor.

  ## Basic Usage

      <.live_editor
        id="my-editor"
        content={@code}
        language={:elixir}
        on_change="code_changed"
      />

  ## With Editor Struct

      <.live_editor
        id="my-editor"
        editor={@editor}
        on_change="editor_changed"
      />

  ## Options

    * `:id` - Required. Unique identifier for the editor component.
    * `:content` - Initial content string (mutually exclusive with `:editor`).
    * `:editor` - An `ExEditor.Editor` struct (mutually exclusive with `:content`).
    * `:language` - Language for syntax highlighting. Default: `:elixir`.
    * `:on_change` - Event name to push when content changes. Default: `"change"`.
    * `:readonly` - Whether the editor is read-only. Default: `false`.
    * `:line_numbers` - Whether to show line numbers. Default: `true`.
    * `:class` - Additional CSS classes for the container.
    * `:debounce` - Debounce time in milliseconds. Default: `300`.
    * `:theme` - Editor theme. Default: `"dark"`.

  ## Examples

      defmodule MyAppWeb.EditorLive do
        use MyAppWeb, :live_view

        def mount(_params, _session, socket) do
          {:ok, assign(socket, :code, "def hello, do: :world")}
        end

        def render(assigns) do
          ~H\"""
          <ExEditorWeb.LiveEditor.live_editor
            id="code-editor"
            content={@code}
            language={:elixir}
            on_change="code_changed"
          />
          \"""
        end

        def handle_event("code_changed", %{"content" => new_code}, socket) do
          {:noreply, assign(socket, :code, new_code)}
        end
      end
  """

  use Phoenix.LiveComponent
  import Phoenix.HTML

  alias ExEditor.{Editor, HighlightedLines, LineNumbers}

  @languages %{
    elixir: ExEditor.Highlighters.Elixir,
    json: ExEditor.Highlighters.JSON
  }

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:editor, nil)
     |> assign(:language, :elixir)
     |> assign(:on_change, "change")
     |> assign(:readonly, false)
     |> assign(:line_numbers, true)
     |> assign(:class, "")
     |> assign(:debounce, 300)
     |> assign(:theme, "dark")}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> maybe_initialize_editor()

    {:ok, socket}
  end

  defp maybe_initialize_editor(%{assigns: %{editor: %Editor{}}} = socket) do
    socket
  end

  defp maybe_initialize_editor(%{assigns: %{content: content}} = socket)
       when is_binary(content) do
    editor =
      Editor.new(content: content)
      |> set_highlighter(socket.assigns.language)

    assign(socket, :editor, editor)
  end

  defp maybe_initialize_editor(socket) do
    editor =
      Editor.new(content: "")
      |> set_highlighter(socket.assigns.language)

    assign(socket, :editor, editor)
  end

  defp set_highlighter(editor, language) do
    case Map.get(@languages, language) do
      nil -> editor
      highlighter -> Editor.set_highlighter(editor, highlighter)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class={"ex-editor-container #{@class}"}
      phx-hook="EditorHook"
      data-readonly={to_string(@readonly)}
      data-debounce={to_string(@debounce)}
      data-on-change={@on_change}
    >
      <div class="ex-editor-wrapper">
        <%= if @line_numbers do %>
          <div class="ex-editor-line-numbers">
            <%= raw LineNumbers.render_for_document(@editor.document) %>
          </div>
        <% end %>

        <pre class="ex-editor-highlight"><%= raw render_highlighted_content(@editor, @line_numbers) %></pre>

        <textarea
          class="ex-editor-textarea"
          name="content"
          phx-target={@myself}
          phx-change="change"
          phx-debounce={@debounce}
          readonly={@readonly}
          spellcheck="false"
        ><%= Editor.get_content(@editor) %></textarea>
      </div>
    </div>
    """
  end

  defp render_highlighted_content(editor, true = _line_numbers) do
    editor
    |> Editor.get_highlighted_content()
    |> HighlightedLines.wrap_lines()
  end

  defp render_highlighted_content(editor, false = _line_numbers) do
    Editor.get_highlighted_content(editor)
  end

  @impl true
  def handle_event("change", %{"content" => content}, socket) do
    editor = socket.assigns.editor

    case Editor.set_content(editor, content) do
      {:ok, updated_editor} ->
        socket = assign(socket, :editor, updated_editor)

        if on_change = socket.assigns.on_change do
          send(self(), {String.to_atom(on_change), %{content: content, editor: updated_editor}})
        end

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @doc """
  Renders a live_editor component.

  This is the function component interface for use in HEEx templates.

  ## Examples

      <.live_editor id="editor" content={@code} language={:elixir} />
  """
  def live_editor(assigns) do
    ~H"""
    <.live_component module={__MODULE__} id={@id} {Map.drop(assigns, [:id])} />
    """
  end
end
