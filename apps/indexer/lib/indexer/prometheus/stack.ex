defmodule Indexer.Stack do
  use Plug.Builder

  plug Indexer.Prometheus.Exporter
  plug Indexer.Health.Plug, []
end
