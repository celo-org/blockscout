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

  defp collector_metrics do
    [
      counter("blockscout.metrics.scrape.count")
    ]
  end

  defp child_processes(metrics) do
    [
      {TelemetryMetricsPrometheus.Core, metrics: get_metrics(metrics)}
    ]
  end

  defp get_metrics(metrics) do
    [collector_metrics() | metrics]
    |> Enum.map( fn
      m when is_list(m) -> m
      module when is_atom(module) -> apply(module, :metrics, [])
    end)
    |> List.flatten()
  end
end