defmodule Demo.Repo.Migrations.CreateCodeSnippets do
  use Ecto.Migration

  def change do
    create table(:code_snippets) do
      add :name, :string
      add :code, :text

      timestamps()
    end
  end
end
