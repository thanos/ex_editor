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
    value = Map.get(attrs, key)
    parse_json_value(attrs, key, value)
  end

  # Handle non-empty string values by attempting JSON decode
  defp parse_json_value(attrs, key, value) when is_binary(value) and value != "" do
    case Jason.decode(value) do
      {:ok, parsed} when is_map(parsed) -> Map.put(attrs, key, parsed)
      _ -> attrs
    end
  end

  # Handle map values - keep as-is
  defp parse_json_value(attrs, _key, value) when is_map(value), do: attrs

  # Handle empty string and nil - convert to empty map
  defp parse_json_value(attrs, key, value) when value == "" or is_nil(value) do
    Map.put(attrs, key, %{})
  end

  # Handle any other value - keep as-is
  defp parse_json_value(attrs, _key, _value), do: attrs
end
