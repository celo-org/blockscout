defmodule EventStream.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Explorer.Celo.Telemetry.MetricsCollector, as: CeloPrometheusCollector

  def start(_type, _args) do
    children = [
      EventStream.Endpoint,
      {CeloPrometheusCollector, metrics: [EventStream.Metrics.metrics()]},
      # Start a worker by calling: EventStream.Worker.start_link(arg)
      # {EventStream.Worker, arg}
      {Phoenix.PubSub, name: EventStream.PubSub}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EventStream.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    EventStream.Endpoint.config_change(changed, removed)
    :ok
  end
end
