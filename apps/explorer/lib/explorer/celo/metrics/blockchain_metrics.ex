defmodule Explorer.Celo.Metrics.BlockchainMetrics do
  @moduledoc "A context to collect blockchain metric functions"

  alias Explorer.Chain.PendingBlockOperation
  alias Explorer.Repo
  import Ecto.Query

  def pending_blockcount do
    query = from(b in PendingBlockOperation, select: fragment("count(*)"), where: b.fetch_internal_transactions == true)

    query |> Repo.one()
  end
end
