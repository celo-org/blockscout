defmodule Explorer.Export.CSV.TokenTransferExporter do
  @moduledoc "Export all TokenTransfer instances for a given account between two dates"

  import Ecto.Query
  alias Explorer.Chain
  alias Explorer.Chain.{Address, Transaction, Wei}
  import Explorer.Export.CSV.Utils

  @behaviour Explorer.Export.CSV.Exporter

  @preloads [
    gas_currency: :token,
    token_transfers: :token,
    token_transfers: :to_address,
    token_transfers: :from_address,
    token_transfers: :token_contract_address,
    from_address: [],
    to_address: [],
    block: []
  ]

  @row_header [
    "TxHash",
    "BlockNumber",
    "Timestamp",
    "FromAddress",
    "ToAddress",
    "TokenContractAddress",
    "Type",
    "TokenSymbol",
    "TokensTransferred",
    "TransactionFee",
    "TransactionFeeCurrency",
    "Status",
    "ErrCode"
  ]

  @impl true
  def query(%Address{hash: address_hash}, from, to) do
    from_block = Chain.convert_date_to_min_block(from)
    to_block = Chain.convert_date_to_max_block(to)

    Transaction
    |> order_by([transaction], desc: transaction.block_number, desc: transaction.index)
    |> Chain.where_block_number_in_period(from_block, to_block)
    |> where(
      [t],
      t.from_address_hash == ^address_hash or t.to_address_hash == ^address_hash or
        t.created_contract_address_hash == ^address_hash
    )
  end

  @impl true
  def associations, do: @preloads

  @impl true
  def row_names, do: @row_header

  @impl true
  def transform(transaction, address) do
    transaction.token_transfers
    |> Enum.map(fn transfer ->
      token_transfer = %{transfer | transaction: transaction}

      [
        to_string(token_transfer.transaction_hash),
        token_transfer.transaction.block_number,
        token_transfer.transaction.block.timestamp,
        token_transfer.from_address |> to_string() |> String.downcase(),
        token_transfer.to_address |> to_string() |> String.downcase(),
        token_transfer.token_contract_address |> to_string() |> String.downcase(),
        type(token_transfer, address.hash),
        token_transfer.token.symbol,
        token_transfer.amount,
        fee(token_transfer.transaction),
        fee_currency(token_transfer.transaction),
        token_transfer.transaction.status,
        token_transfer.transaction.error
      ]
    end)
  end
end
