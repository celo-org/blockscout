defmodule Explorer.Export.CSV.EpochTransactionExporter do
  @moduledoc "Export all Epoch Transactions for given address"

  import Ecto.Query

  import Ecto.Query,
    only: [
      from: 2
    ]

  alias Explorer.Celo.EpochUtil
  alias Explorer.Chain
  alias Explorer.Chain.{Address, CeloElectionRewards, Wei}

  @behaviour Explorer.Export.CSV.Exporter

  @preloads []

  @row_header [
    "Epoch",
    "BlockNumber",
    "TimestampUTC",
    "EpochTxType",
    "FromAddress",
    "ToAddress",
    "TokenSymbol",
    "TokenContractAddress",
    "Type",
    "Value",
    "ValueInWei"
  ]

  @impl true
  def query(%Address{hash: address_hash}, from, to) do
    from_block = Chain.convert_date_to_min_block(from)
    to_block = Chain.convert_date_to_max_block(to)

    query =
      from(rewards in CeloElectionRewards,
        select: %{
          epoch_number: fragment("? / 17280", rewards.block_number),
          block_number: rewards.block_number,
          timestamp: rewards.block_timestamp,
          epoch_tx_type: rewards.reward_type,
          from_address: rewards.associated_account_hash,
          to_address: rewards.account_hash,
          value_wei: rewards.amount
        },
        order_by: [desc: rewards.block_number, asc: rewards.reward_type],
        where: rewards.account_hash == ^address_hash,
        where: rewards.amount > ^%Wei{value: Decimal.new(0)}
      )

    query |> Chain.where_block_number_in_period(from_block, to_block)
  end

  @impl true
  def associations, do: @preloads

  @impl true
  def row_names, do: @row_header

  @impl true
  def transform(epoch_transaction, _address) do
    [
      #      "Epoch",
      epoch_transaction.epoch_number,
      #      "BlockNumber",
      epoch_transaction.block_number,
      #      "TimestampUTC",
      to_string(epoch_transaction.timestamp),
      #      "EpochTxType",
      epoch_transaction.epoch_tx_type |> reward_type_to_human_readable,
      #      "FromAddress",
      to_string(epoch_transaction.from_address),
      #      "ToAddress",
      to_string(epoch_transaction.to_address),
      #      "TokenSymbol",
      epoch_transaction.epoch_tx_type |> token_symbol(),
      #      "TokenContractAddress",
      epoch_transaction.epoch_tx_type |> EpochUtil.get_reward_currency_address_hash(),
      #      "Type",
      "IN",
      #      "Value",
      Wei.to(epoch_transaction.value_wei, :ether),
      #      "ValueInWei",
      Wei.to(epoch_transaction.value_wei, :wei)
    ]
  end

  defp reward_type_to_human_readable("voter"), do: "Voter Rewards"
  defp reward_type_to_human_readable("validator"), do: "Validator Rewards"
  defp reward_type_to_human_readable("group"), do: "Validator Group Rewards"

  defp token_symbol("voter"), do: "CELO"
  defp token_symbol(type) when type in ["validator", "group"], do: "cUSD"
end
