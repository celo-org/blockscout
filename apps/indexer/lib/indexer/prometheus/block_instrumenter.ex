defmodule Indexer.Prometheus.BlockInstrumenter do
  @moduledoc """
  Instrument block related metrics.
  """
  use Prometheus.Metric

  def setup do
    events = [
      [:reorgs]
    ]

    Enum.each(events, &setup_event/1)
  end

  defp setup_event(event) do
    name = "indexer_blocks_#{Enum.join(event, "_")}"

    Counter.declare(
      name: String.to_atom("#{name}_total"),
      help: "Total count of tracking for block event #{name}"
    )

    :telemetry.attach(name, [:indexer, :blocks | event], &handle_event/4, nil)
  end

  def handle_event([:indexer, :blocks, :reorgs], _value, _metadata, _config) do
    Counter.inc(name: :indexer_blocks_reorgs_total)
  end
end
