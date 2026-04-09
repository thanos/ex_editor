defmodule Demo.CMS.CodeSnippet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "code_snippets" do
    field :name, :string
    field :code, :string
    field :args, :map, default: %{}

    timestamps()
  end

  @doc false
  def changeset(code_snippet, attrs, _meta \\ []) do
    attrs = parse_json_field(attrs, "args")

    code_snippet
    |> cast(attrs, [:name, :code, :args])
    |> validate_required([:name, :code])
  end

  defp parse_json_field(attrs, key) when is_map(attrs) do
    case Map.get(attrs, key) do
      value when is_binary(value) and value != "" ->
        case Jason.decode(value) do
          {:ok, parsed} -> Map.put(attrs, key, parsed)
          {:error, _} -> attrs
        end

      _ ->
        attrs
    end
  end
end
