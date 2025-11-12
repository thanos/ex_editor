
defmodule DemoWeb.RedirectController do
  use DemoWeb, :controller

  def redirect_to_snipptes(conn, _params) do
    conn
    |> Phoenix.Controller.redirect(to: ~p"/admin/code_snippets")
    |> Plug.Conn.halt()
  end
end
