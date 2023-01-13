defmodule Explorer.Celo.Telemetry.Instrumentation.Blockchain do
  alias Explorer.Celo.Telemetry.Instrumentation
  use Instrumentation

  def metrics() do
  [
    last_value(
      "indexer_blocks_last_block_number_current",
      event_name: [:indexer, :blocks, :last_block_number],
      measurement: :value,
      description: "Max block number found in DB")
  ]
  end
end