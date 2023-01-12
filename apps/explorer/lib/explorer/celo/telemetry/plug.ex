defmodule Explorer.Celo.Telemetry.Plug do
  @moduledoc """
   A plug to expose defined metrics to prometheus at endpoint /metrics
  """

  @behaviour Plug
  import Plug.Conn
  require Logger

  alias Explorer.Celo.Telemetry, as: Telemetry

  #nop
  def init(_opts) do
  end

  @metrics_path "/metrics"

  def call(conn, _opts) do
    case conn.request_path do
      @metrics_path ->
        Telemetry.event([:metrics, :scrape])

        metrics = TelemetryMetricsPrometheus.Core.scrape()

        conn
        |> put_private(:prometheus_metrics_name, :prometheus_metrics)
        |> put_resp_content_type("text/plain")
        |> send_resp(200, metrics)
        |> halt()

      _ -> conn
    end
  end
end