defmodule Explorer.Celo.Telemetry.MetricsCollector do
  use Supervisor
  import Telemetry.Metrics

  require Logger

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(arg) do
    metrics = Keyword.get(arg, :metrics, [])
    Supervisor.init(child_processes(metrics), strategy: :one_for_one)
  end

  defp metrics do
    [
      counter("blockscout.metrics.scrape.count")
    ]
  end

  defp child_processes(metrics) do
    all_metrics =
      metrics ++ metrics()
      |> List.flatten()

    [
      {TelemetryMetricsPrometheus.Core, metrics: all_metrics}
    ]
  end
end