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
    attrs |> dbg()
    attrs = parse_json_field(attrs, "args")

    code_snippet
    |> cast(attrs, [:name, :code, :args])
    |> validate_required([:name, :code])
  end

  defp parse_json_field(attrs, key) when is_map(attrs) do
    case Map.get(attrs, key) do
      value when is_binary(value) and value != "" ->
        # Try to parse JSON string to map
        case Jason.decode(value) do
          {:ok, parsed} when is_map(parsed) ->
            Map.put(attrs, key, parsed)

          {:ok, _other} ->
            # JSON is valid but not an object - store as-is
            attrs

          {:error, _} ->
            # Invalid JSON - keep the string as-is and let validation handle it
            attrs
        end

      value when is_map(value) ->
        # Already a map, keep as-is
        attrs

      "" ->
        # Empty string - set to empty map
        Map.put(attrs, key, %{})

      nil ->
        # nil - set to empty map
        Map.put(attrs, key, %{})

      _other ->
        attrs
    end
  end
end
