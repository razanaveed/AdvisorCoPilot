defmodule AdvisorCoPilot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    AdvisorCoPilot.Release.migrate()
    children = [
      AdvisorCoPilotWeb.Telemetry,
      AdvisorCoPilot.Repo,
      {DNSCluster, query: Application.get_env(:advisor_co_pilot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AdvisorCoPilot.PubSub},
      {Task.Supervisor, name: AdvisorCoPilot.Intelligence.TaskSupervisor},
      AdvisorCoPilot.Intelligence.Tagger,
      # Start to serve requests, typically the last entry
      AdvisorCoPilotWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AdvisorCoPilot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AdvisorCoPilotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
