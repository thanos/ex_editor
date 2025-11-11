defmodule DemoWeb.Admin.BlogPostLive do
  use Backpex.LiveResource,
    layout: {DemoWeb.Layouts, :admin},
    adapter_config: [
      schema: Demo.BlogPost,
      repo: Demo.Repo,
      update_changeset: &Demo.BlogPost.changeset/3,
      create_changeset: &Demo.BlogPost.changeset/3
    ],
    pubsub: [
      server: Demo.PubSub,
      topic: "blog_posts"
    ]

  @impl Backpex.LiveResource
  def singular_name(), do: "Blog Post"

  @impl Backpex.LiveResource
  def plural_name(), do: "Blog Posts"

  @impl Backpex.LiveResource
  def fields do
    [
      title: %{
        module: Backpex.Fields.Text,
        label: "Title",
        searchable: true
      },
      slug: %{
        module: Backpex.Fields.Text,
        label: "Slug",
        searchable: true
      },
      status: %{
        module: Backpex.Fields.Select,
        label: "Status",
        options: [
          draft: "Draft",
          published: "Published",
          archived: "Archived"
        ]
      },
      excerpt: %{
        module: Backpex.Fields.Textarea,
        label: "Excerpt"
      },
      content: %{
        module: Backpex.Fields.Textarea,
        label: "Content"
      },
      published_at: %{
        module: Backpex.Fields.DateTime,
        label: "Published At"
      },
      inserted_at: %{
        module: Backpex.Fields.DateTime,
        label: "Created At",
        readonly: true
      },
      updated_at: %{
        module: Backpex.Fields.DateTime,
        label: "Updated At",
        readonly: true
      }
    ]
  end
end
