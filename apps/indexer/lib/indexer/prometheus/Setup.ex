defmodule Indexer.Prometheus.Setup do
  def setup() do
    Prometheus.TransactionInstrumenter.setup()

    Indexer.Prometheus.Exporter.setup()
  end
end
