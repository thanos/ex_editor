defmodule DemoWeb.Admin.CodeSnippetLive do
  alias Demo.CMS.CodeSnippet
  alias DemoWeb.Layouts

  use Backpex.LiveResource,
    adapter_config: [
      schema: CodeSnippet,
      repo: Demo.Repo,
      update_changeset: &CodeSnippet.changeset/3,
      create_changeset: &CodeSnippet.changeset/3,
      item_query: &__MODULE__.item_query/3
    ],
    on_mount: {__MODULE__, :local_hook}

  import Ecto.Query, only: [from: 2]

  @impl Backpex.LiveResource
  def layout(_assigns), do: {Layouts, :admin}

  def on_mount(:local_hook, _params, _session, socket) do
    editor = ExEditor.Editor.new(content: "")
    editor = ExEditor.Editor.set_highlighter(editor, ExEditor.Highlighters.Elixir)

    {:cont,
     socket
     |> assign(:editor, editor)
     |> assign(:cursor_line, 1)
     |> assign(:cursor_col, 1)}
  end

  @impl Backpex.LiveResource
  def singular_name, do: "Code Snippet"

  @impl Backpex.LiveResource
  def plural_name, do: "Code Snippets"

  def item_query(query, :edit, assigns), do: item_query(query, :show, assigns)

  def item_query(_query, :show, %{params: %{"backpex_id" => id}}) do
    query = from(c0 in CodeSnippet, as: :codesnippet, where: c0.id == ^id, select: c0)
    query
  end

  def item_query(query, _, _assigns), do: query

  # Handle code_changed events from the LiveEditor component
  def handle_info({:code_changed, %{content: new_code}}, socket) do
    {:noreply, assign(socket, :editor_content, new_code)}
  end

  @impl Backpex.LiveResource
  def fields do
    [
      name: %{
        module: Backpex.Fields.Text,
        label: "Name"
      },
      code: %{
        module: DemoWeb.Admin.Fields.EditField,
        rows: 10,
        label: "Code"
      },
      args: %{
        module: Backpex.Fields.Textarea,
        label: "Args (JSON)",
        rows: 5,
        render: {__MODULE__, :render_args_value}
      }
    ]
  end

  def render_args_value(assigns) do
    import Phoenix.Component, only: [sigil_H: 2]

    ~H"""
    <pre class="text-sm bg-gray-100 dark:bg-gray-800 rounded p-2 overflow-x-auto whitespace-pre-wrap"><%= format_json(@value) %></pre>
    """
  end

  defp format_json(nil), do: "{}"
  defp format_json(value) when is_map(value), do: Jason.encode!(value, pretty: true)
  defp format_json(value) when is_binary(value), do: value
end
