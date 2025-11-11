defmodule DemoWeb.Admin.BlogPostLive do
  use Backpex.LiveResource,
    layout: {DemoWeb.Layouts, :admin},
    schema: Demo.BlogPost,
    repo: Demo.Repo,
    update_changeset: &Demo.BlogPost.changeset/2,
    create_changeset: &Demo.BlogPost.changeset/2,
    pubsub: Demo.PubSub,
    topic: "blog_posts",
    event_prefix: "blog_post_"

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
        can_edit: false
      },
      updated_at: %{
        module: Backpex.Fields.DateTime,
        label: "Updated At",
        can_edit: false
      }
    ]
  end

  @impl Backpex.LiveResource
  def index_columns do
    [:title, :slug, :status, :published_at, :inserted_at]
  end

  @impl Backpex.LiveResource
  def show_columns do
    [:title, :slug, :status, :excerpt, :content, :published_at, :inserted_at, :updated_at]
  end

  @impl Backpex.LiveResource
  def form_columns do
    [:title, :slug, :status, :excerpt, :content, :published_at]
  end
end
