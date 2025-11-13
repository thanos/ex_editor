defmodule Demo.CMS.CodeSnippet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "code_snippets" do
    field :name, :string
    field :code, :string

    timestamps()
  end

  @doc false
  def changeset(code_snippet, attrs, meta \\ []) do
    code_snippet
    |> cast(attrs, [:name, :code])
    |> validate_required([:name, :code])
  end
end
