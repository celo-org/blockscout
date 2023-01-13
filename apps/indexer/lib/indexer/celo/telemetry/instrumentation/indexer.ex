defmodule Indexer.Celo.Telemetry.Instrumentation do
  alias Explorer.Celo.Telemetry.Instrumentation

  use Instrumentation

  def metrics() do
    [
      counter("indexer.import.ingested",
        event_name: [:blockscout, :ingested],
        measurement: :count,
        description: "Blockchain primitives ingested via `Import.all` by type",
        tags: [:type]
      ),
      last_value(
        "indexer_blocks_pending_blockcount_current",
        event_name: [:indexer, :blocks, :pending_blockcount],
        measurement: :value,
        description: "Number of rows in pending_block_operations table / blocks that still need itx fetched"),
      last_value(
        "indexer_blocks_pending_current",
        event_name: [:indexer, :blocks, :pending],
        measurement: :value,
        description: "Number of blocks still to be fetched in past range"),
    ]
  end
end