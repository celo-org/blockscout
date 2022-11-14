defmodule Explorer.Export.CSV.EpochTransactionExporter do
  @moduledoc "Export all Epoch Transactions for given address"

  import Ecto.Query
  alias Explorer.Chain
  alias Explorer.Chain.{Address, CeloElectionRewards, Wei}
  import Explorer.Export.CSV.Utils

  import Ecto.Query,
    only: [
      from: 2
    ]

  @behaviour Explorer.Export.CSV.Exporter

  @preloads []

  @row_header [
    "EpochNumber",
    "BlockNumber",
    "Timestamp",
    "FromAddress",
    "RewardType",
    "Value"
  ]

  @impl true
  def query(%Address{hash: address_hash}, _from, _to) do
    #    from_block = Chain.convert_date_to_min_block(from)
    #    to_block = Chain.convert_date_to_max_block(to)

    from(rewards in CeloElectionRewards,
      select: %{
        associated_account_hash: rewards.associated_account_hash,
        value: rewards.amount,
        from_address: rewards.associated_account_hash,
        block_number: rewards.block_number,
        timestamp: rewards.block_timestamp,
        epoch_number: fragment("? / 17280", rewards.block_number),
        reward_type: rewards.reward_type
      },
      order_by: [desc: rewards.block_number, asc: rewards.reward_type],
      where: rewards.account_hash == ^address_hash,
      where: rewards.amount > ^%Wei{value: Decimal.new(0)}
    )
  end

  @impl true
  def associations, do: @preloads

  @impl true
  def row_names, do: @row_header

  @impl true
  def transform(epoch_transaction, address) do
    [
      epoch_transaction.epoch_number,
      epoch_transaction.block_number,
      to_string(epoch_transaction.timestamp),
      to_string(epoch_transaction.associated_account_hash),
      epoch_transaction.reward_type,
      Wei.to(epoch_transaction.value, :wei)
    ]
  end
end
