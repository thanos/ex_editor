defmodule ExEditor.Repo do
  use Ecto.Repo,
    otp_app: :ex_editor,
    adapter: Ecto.Adapters.SQLite3
end
