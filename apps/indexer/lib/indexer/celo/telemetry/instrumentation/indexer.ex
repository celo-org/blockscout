defmodule Indexer.Celo.Telemetry.Instrumentation do
  @moduledoc "Metrics for the Indexer application"

  alias Explorer.Celo.Telemetry.Instrumentation

  use Instrumentation

  def metrics do
    [
      counter("indexer_import_ingested",
        event_name: [:blockscout, :ingested],
        measurement: :count,
        description: "Blockchain primitives ingested via `Import.all` by type",
        tags: [:type]
      ),
      counter("indexer_chain_events_sent",
        event_name: [:blockscout, :chain_event_send],
        measurement: :count,
        description: "Pubsub notifications sent via erlang cluster"
      ),
      last_value(
        "indexer_blocks_pending_blockcount_current",
        event_name: [:indexer, :blocks, :pending_blockcount],
        measurement: :value,
        description: "Number of rows in pending_block_operations table / blocks that still need itx fetched"
      ),
      last_value(
        "indexer_blocks_pending_current",
        event_name: [:indexer, :blocks, :pending],
        measurement: :value,
        description: "Number of blocks still to be fetched in past range"
      ),
      last_value(
        "indexer_fetcher_config_concurrency_current",
        event_name: [:blockscout, :fetcher, :config],
        measurement: :concurrency,
        description: "Max concurrent fetcher processes",
        tags: [:fetcher]
      ),
      last_value(
        "indexer_fetcher_config_batch_size_current",
        event_name: [:blockscout, :fetcher, :config],
        measurement: :batch_size,
        description: "Max batch size for fetcher (number of items each fetcher process will work upon)",
        tags: [:fetcher]
      ),
    ]
  end
end
