defmodule Indexer.Prometheus.BlockInstrumenter do
  @moduledoc """
  Instrument block related metrics.
  """

  def setup do
    gauge_events = [
      [:pending],
      [:pending_blockcount]
    ]

    Enum.each(gauge_events, &setup_gauge/1)
  end



  defp setup_gauge(_event) do
#    name = "indexer_blocks_#{Enum.join(event, "_")}"

#    Gauge.declare(
#      name: String.to_atom("#{name}_current"),
#      help: "Current number of tracking for block event #{name}"
#    )
#
#    :telemetry.attach(name, [:indexer, :blocks | event], &handle_set_event/4, nil)
  end

#  def handle_set_event([:indexer, :blocks, :pending], %{value: val}, _metadata, _config) do
##    Gauge.set([name: :indexer_blocks_pending_current], val)
#  end
#
#
#  def handle_set_event([:indexer, :blocks, :pending_blockcount], %{value: val}, _metadata, _config) do
##    Gauge.set([name: :indexer_blocks_pending_blockcount_current], val)
#  end
end
