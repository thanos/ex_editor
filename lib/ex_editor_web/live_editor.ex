defmodule ExEditorWeb.LiveEditor do
  @moduledoc """
  A LiveView component for displaying an editable code editor with syntax highlighting.

  Uses a "double-buffer" technique: an invisible textarea captures user input
  while a visible layer renders syntax-highlighted code. The textarea is owned
  entirely by JavaScript after mount (`phx-update="ignore"`), preventing LiveView
  from overwriting user input during re-renders.

  ## Usage

      <.live_component
        module={ExEditorWeb.LiveEditor}
        id="my-editor"
        content={@code}
        language={:elixir}
        on_change="code_changed"
      />

  The parent LiveView receives changes via `handle_info/2`:

      def handle_info({:code_changed, %{content: new_code}}, socket) do
        {:noreply, assign(socket, :code, new_code)}
      end

  ## Options

    * `:id` - Required. Unique identifier for the editor.
    * `:content` - Initial content string. Only used on first mount.
    * `:language` - Language for highlighting. Default: `:elixir`.
    * `:on_change` - Atom name for parent notification. Default: `"code_changed"`.
    * `:readonly` - Read-only mode. Default: `false`.
    * `:line_numbers` - Show line numbers. Default: `true`.
    * `:class` - Additional CSS classes.
    * `:debounce` - Debounce in ms. Default: `300`.
  """

  use Phoenix.LiveComponent
  import Phoenix.HTML

  alias ExEditor.{Editor, HighlightedLines}

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
     |> assign(:on_change, "code_changed")
     |> assign(:readonly, false)
     |> assign(:line_numbers, true)
     |> assign(:class, "")
     |> assign(:debounce, 300)}
  end

  @impl true
  def update(assigns, socket) do
    # Only initialize editor on first update (when editor is nil)
    if socket.assigns[:editor] == nil do
      socket =
        socket
        |> assign(assigns)
        |> initialize_editor()

      {:ok, socket}
    else
      # On subsequent updates, only update non-content assigns
      # The editor owns its own content state
      socket =
        assigns
        |> Map.drop([:content])
        |> then(&assign(socket, &1))

      {:ok, socket}
    end
  end

  defp initialize_editor(%{assigns: %{content: content}} = socket) when is_binary(content) do
    editor =
      Editor.new(content: content)
      |> set_highlighter(socket.assigns.language)

    assign(socket, :editor, editor)
  end

  defp initialize_editor(socket) do
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
      data-debounce={to_string(@debounce)}
      phx-target={@myself}
    >
      <div class="ex-editor-wrapper">
        <%= if @line_numbers do %>
          <%!-- Gutter: owned by JS after mount, LiveView will NOT patch this --%>
          <div class="ex-editor-gutter" id={"#{@id}-gutter"} phx-update="ignore">
            <%= for num <- 1..line_count(@editor) do %>
              <div class="ex-editor-line-number"><%= num %></div>
            <% end %>
          </div>
        <% end %>

        <div class="ex-editor-code-area">
          <%!-- Highlighted layer: updated by server on every change --%>
          <pre class="ex-editor-highlight" id={"#{@id}-highlight"}><%= raw render_highlighted_content(@editor) %></pre>

          <%!-- Textarea: owned by JS after mount, LiveView will NOT patch this --%>
          <div id={"#{@id}-textarea-wrap"} phx-update="ignore">
            <textarea
              id={"#{@id}-textarea"}
              class="ex-editor-textarea"
              readonly={@readonly}
              spellcheck="false"
            ><%= Editor.get_content(@editor) %></textarea>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp line_count(editor) do
    ExEditor.Document.line_count(editor.document)
  end

  defp render_highlighted_content(editor) do
    editor
    |> Editor.get_highlighted_content()
    |> HighlightedLines.wrap_lines_with_empties()
  end

  @impl true
  def handle_event("change", %{"content" => content}, socket) do
    editor = socket.assigns.editor

    case Editor.set_content(editor, content) do
      {:ok, updated_editor} ->
        # Notify parent LiveView
        if on_change = socket.assigns.on_change do
          send(socket.root_pid, {String.to_atom(on_change), %{content: content}})
        end

        {:noreply, assign(socket, :editor, updated_editor)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @doc """
  Renders a live_editor component.

  ## Examples

      <.live_editor id="editor" content={@code} language={:elixir} />
  """
  def live_editor(assigns) do
    ~H"""
    <.live_component module={__MODULE__} id={@id} {Map.drop(assigns, [:id])} />
    """
  end
end
