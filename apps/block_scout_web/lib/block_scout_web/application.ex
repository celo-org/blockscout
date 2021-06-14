defmodule BlockScoutWeb.Application do
  @moduledoc """
  Supervises `BlockScoutWeb.Endpoint` in order to serve Web UI.
  """

  use Application

  alias BlockScoutWeb.Counters.BlocksIndexedCounter
  alias BlockScoutWeb.{Endpoint, Prometheus}
  alias BlockScoutWeb.RealtimeEventHandler
  alias Prometheus.{Exporter, GenericInstrumenter, Instrumenter}

  def start(_type, _args) do
    import Supervisor.Spec

    Exporter.setup()
    GenericInstrumenter.setup()
    Instrumenter.setup()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      {Phoenix.PubSub.PG2, name: BlockScoutWeb.PubSub, fastlane: Phoenix.Channel.Server},
      supervisor(Endpoint, []),
      supervisor(Absinthe.Subscription, [Endpoint]),
      {RealtimeEventHandler, name: RealtimeEventHandler},
      {BlocksIndexedCounter, name: BlocksIndexedCounter}
    ]

    opts = [strategy: :one_for_one, name: BlockScoutWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
