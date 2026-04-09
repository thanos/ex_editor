defmodule Demo.Repo.Migrations.AddArgsToCodeSnippets do
  use Ecto.Migration

  def change do
    alter table(:code_snippets) do
      add :args, :map, default: %{}
    end
  end
end
