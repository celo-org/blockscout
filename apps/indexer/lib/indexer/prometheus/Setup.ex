defmodule Indexer.Prometheus.Setup do
  @moduledoc """
  Set up instrumenters and exporter here to keep application.ex clean
  """

  alias Indexer.Prometheus.{Exporter, TransactionInstrumenter}

  def setup do
    TransactionInstrumenter.setup()

    Exporter.setup()
  end
end
