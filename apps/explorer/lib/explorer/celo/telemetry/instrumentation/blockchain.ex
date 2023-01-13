defmodule Explorer.Celo.Telemetry.Instrumentation.Blockchain do
  alias Explorer.Celo.Telemetry.Instrumentation
  use Instrumentation


  def metrics() do
    # metric names reference `indexer` + appended with `_current` for backwards compatibility
  [
    last_value(
      "indexer_blocks_last_block_number_current",
      event_name: [:indexer, :blocks, :last_block_number],
      measurement: :value,
      description: "Max block number found in DB"),
    last_value(
      "indexer_blocks_last_block_age_current",
      event_name: [:indexer, :blocks, :last_block_age],
      measurement: :value,
      description: "Difference between max block timestamp and current DB time"),
    last_value(
      "indexer_blocks_average_time_current",
      event_name: [:indexer, :blocks, :average_time],
      measurement: :value,
      description: "Average block time over past 100 blocks"),
    last_value(
      "indexer_transactions_total_current",
      event_name: [:indexer, :transactions, :total],
      measurement: :value,
      description: "Count of transactions in the transactions table"),
    last_value(
      "indexer_transactions_pending_current",
      event_name: [:indexer, :transactions, :pending],
      measurement: :value,
      description: "Count of pending transactions in the transactions table"),
  ]
  end
end