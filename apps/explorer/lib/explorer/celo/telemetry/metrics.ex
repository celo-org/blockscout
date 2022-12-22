defmodule Explorer.Celo.Telemetry.Metrics do
  use Supervisor
  import Telemetry.Metrics

  require Logger

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {TelemetryMetricsPrometheus, metrics: metrics(), port: 4001}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp metrics do
    Logger.info("Metrics")
    [
      counter("blockscout.chain_event_send.payload_size", description: "chain events sent"),
                                                          counter("http.request.count")

    ]
  end
end