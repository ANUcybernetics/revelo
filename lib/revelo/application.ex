defmodule Revelo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ReveloWeb.Telemetry,
      Revelo.Repo,
      {Ecto.Migrator, repos: Application.fetch_env!(:revelo, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:revelo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Revelo.PubSub},
      {Registry, keys: :unique, name: Revelo.SessionRegistry},
      ReveloWeb.Presence,
      Revelo.SessionSupervisor,
      # Start the Finch HTTP client for sending emails
      {Finch, name: Revelo.Finch},
      TwMerge.Cache,
      # Start a worker by calling: Revelo.Worker.start_link(arg)
      # {Revelo.Worker, arg},
      # Start to serve requests, typically the last entry
      ReveloWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :revelo]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Revelo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ReveloWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations? do
    # By default, postgres migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
