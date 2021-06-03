defmodule Indexer.Prometheus.Setup do
  @moduledoc """
  Set up instrumenters and exporter here to keep application.ex clean
  """

  alias Indexer.Prometheus.{BlockInstrumenter, DBInstrumenter, Exporter, GenericInstrumenter, TransactionInstrumenter}

  def setup do
    BlockInstrumenter.setup()
    DBInstrumenter.setup()
    GenericInstrumenter.setup()
    TransactionInstrumenter.setup()

    Exporter.setup()
  end
end
