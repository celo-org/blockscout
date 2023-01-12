defmodule Explorer.Celo.Telemetry.Plug do
  @moduledoc """
   A plug to expose defined metrics to prometheus at endpoint /metrics
  """

  @behaviour Plug
  import Plug.Conn
  require Logger

  def init(_opts) do
    Logger.info("!!! Initialized metrics plug")
  end

  def call(conn, _opts) do
    Logger.info("hello #{inspect(conn)}")
    case conn.request_path do
      "/metrics" ->
        Logger.info("double #{inspect(conn)}")
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, "hello i am metrics")

      _ -> conn
    end
  end
end