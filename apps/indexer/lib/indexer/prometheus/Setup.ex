defmodule Indexer.Prometheus.Setup do
  @moduledoc """
  Set up instrumenters and exporter here to keep application.ex clean
  """

  alias Indexer.Prometheus.{BlockInstrumenter, Exporter, TransactionInstrumenter}

  def setup do
    BlockInstrumenter.setup()
    TransactionInstrumenter.setup()

    Exporter.setup()
  end
end
