defmodule Warships.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false


  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WarshipsWeb.Telemetry,
      Warships.RoomStore,
      Warships.ChatStore,
      Warships.RoomSupervisor,
      Warships.LiveMonitor,
      Warships.StoreRegistry,
      # Warships.Repo,
      {DNSCluster, query: Application.get_env(:warships, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Warships.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Warships.Finch},
      # Start a worker by calling: Warships.Worker.start_link(arg)
      # {Warships.Worker, arg},
      # Start to serve requests, typically the last entry
      WarshipsWeb.Presence,
      WarshipsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Warships.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WarshipsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
