defmodule Indexer.Prometheus.RPCInstrumenter do
  use Prometheus.Metric
  require Logger

  def setup do
    Histogram.new(
      name: :http_request_duration_milliseconds,
      buckets: [100, 300, 500, 750, 1000, 3000],
      duration_unit: false,
      labels: [:method],
      help: "Http Request execution time."
    )
  end

  def instrument(%{time: time, method: method}) do
    Histogram.observe(
      [name: :http_request_duration_milliseconds, labels: [method]],
      time
    )
  end
end
