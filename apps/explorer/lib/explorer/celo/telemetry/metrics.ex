defmodule Explorer.Celo.Telemetry.Metrics do
  use Supervisor
  import Telemetry.Metrics

  require Logger

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    Supervisor.init(child_processes(), strategy: :one_for_one)
  end

  defp metrics do
    [
      counter("blockscout.chain_event_send.payload_size", description: "chain events sent"),
      counter("blockscout.metrics.scrape.count"),
      counter("indexer.import.ingested", event_name: [:blockscout, :ingested], measurement: :none),
    ]
  end

  defp child_processes() do
    [
      {TelemetryMetricsPrometheus.Core, metrics: metrics()}
    ]
  end
end