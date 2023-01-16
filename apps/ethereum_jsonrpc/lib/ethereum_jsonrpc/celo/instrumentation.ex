defmodule EthereumJSONRPC.Celo.Instrumentation do
  # not using Explorer.Celo.Telemetry.Instrumentation to prevent circular dependency

  import Telemetry.Metrics

  def metrics() do
    [
      counter("ethereum_jsonrpc.http_request.start.count", description: "Count of HTTP requests attempted"),
      distribution("http_request_duration_milliseconds",
        reporter_options: [buckets: [50, 100, 500, 1000, 10_000, :timer.minutes(1), :timer.minutes(3), :timer.minutes(5), :timer.minutes(10)]],
        event_name: [:ethereum_jsonrpc, :http_request, :stop],
        measurement: :duration,
        description: "Reponse times of requests sent via http to blockchain node",
        tags: [:method, :status_code],
        unit: {:native, :millisecond}
      )
    ]
  end
end