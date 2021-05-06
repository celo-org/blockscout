defmodule Indexer.Prometheus.TransactionInstrumenter do
  @moduledoc """
  Instrument transaction related metrics.
  """
  use Prometheus.Metric

  def setup do
    events = [
      [:pending]
    ]

    Enum.each(events, &setup_event/1)
  end

  defp setup_event(event) do
    name = "indexer_transactions_#{Enum.join(event, "_")}"

    Counter.declare(
      name: String.to_atom("#{name}_total"),
      help: "Total count of tracking for transaction event #{name}"
    )

    :telemetry.attach(name, [:indexer, :transactions | event], &handle_event/4, nil)
  end

  def handle_event([:indexer, :transactions, :pending], _value, _metadata, _config) do
    Counter.inc(name: :indexer_transactions_pending_total)
  end
end
