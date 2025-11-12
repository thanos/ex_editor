defmodule DemoWeb.Admin.CodeSnippetLive do
    use Backpex.LiveResource,
      adapter_config: [
        schema: Demo.CMS.CodeSnippet,
        repo: Demo.Repo,
        update_changeset: &Demo.CMS.CodeSnippet.changeset/3,
        create_changeset: &Demo.CMS.CodeSnippet.changeset/3
      ],
      layout: {DemoWeb.Layouts, :admin}

    @impl Backpex.LiveResource
    def singular_name, do: "Code Snippet"

    @impl Backpex.LiveResource
    def plural_name, do: "Code Snippets"

    @impl Backpex.LiveResource
    def fields do
      [
        name: %{
          module: Backpex.Fields.Text,
          label: "Name"
        },
        code: %{
          module: Backpex.Fields.Textarea,
          rows: 10,
          label: "Code"
        }
      ]
    end


end
