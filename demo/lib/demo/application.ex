defmodule Demo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        DemoWeb.Telemetry
      ] ++
        repo_children() ++
        [
          {DNSCluster, query: Application.get_env(:demo, :dns_cluster_query) || :ignore},
          {Phoenix.PubSub, name: Demo.PubSub},
          DemoWeb.Endpoint
        ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for more strategies and supported options
    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp repo_children do
    if System.get_env("SKIP_MIGRATIONS") == "true" do
      []
    else
      [
        Demo.Repo,
        {Ecto.Migrator,
         repos: Application.fetch_env!(:demo, :ecto_repos), skip: skip_migrations?()}
      ]
    end
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
