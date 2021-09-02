defmodule Explorer.Celo.Metrics.BlockchainMetrics do
  @moduledoc "A context to collect blockchain metric functions"

  alias Explorer.Repo
  alias Ecto.Adapters.SQL

  def pending_blockcount do
    #todo: use ecto

    {:ok, %{rows: [[block_count]]}} = SQL.query(Repo,
      "select count(*) from pending_block_operations where fetch_internal_transactions = true")

    block_count
  end
end