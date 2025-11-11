defmodule Demo.Repo.Migrations.CreateBlogPosts do
  use Ecto.Migration

  def change do
    create table(:blog_posts) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :content, :text
      add :excerpt, :text
      add :published_at, :utc_datetime
      add :status, :string, default: "draft", null: false

      timestamps()
    end

    create unique_index(:blog_posts, [:slug])
  end
end
