defmodule ExEditorWeb.PageController do
  use ExEditorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
