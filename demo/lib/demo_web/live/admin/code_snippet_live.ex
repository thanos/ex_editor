defmodule DemoWeb.Admin.CodeSnippetLive do
    use Backpex.LiveResource,
      adapter_config: [
        schema: Demo.CMS.CodeSnippet,
        repo: Demo.Repo,
        update_changeset: &Demo.CMS.CodeSnippet.changeset/3,
        create_changeset: &Demo.CMS.CodeSnippet.changeset/3,
        item_query: &__MODULE__.item_query/3
      ],
      on_mount: {__MODULE__, :local_hook},
      layout: {DemoWeb.Layouts, :admin}

    import Ecto.Query, only: [from: 2]


    def on_mount(:local_hook, _params, _session, socket) do
      {:ok, editor} = ExEditor.Editor.new(content: "")
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


    def item_query(query, :edit,  assigns), do: item_query(query, :show, assigns)
    def item_query(query, :show,  %{params: %{"backpex_id" => id}}) do
      query = from c0 in Demo.CMS.CodeSnippet, as: :codesnippet, where: c0.id == ^id,   select: c0
      query
    end

    def item_query(query, _,  _assigns),  do: query

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
        }
      ]
    end


end
