defmodule Indexer.Stack do
  @moduledoc """
  Combine prometheus exporter with the health plug
  """
  use Plug.Builder

  plug(Explorer.Celo.Telemetry.Plug)
  plug(Indexer.Health.Plug, [])
end
