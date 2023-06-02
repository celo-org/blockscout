alias Explorer.Repo
import Ecto.Query

defmodule SQLHelper do
  def to_string(query), do: Ecto.Adapters.SQL.to_sql(:all, Explorer.Repo, query) |> IO.inspect()
end

defmodule Clabs.Debug do
  alias Explorer.Chain.{TokenTransfer, Transaction, Block, Token}
  alias Explorer.Chain.Hash.Address


  def new_query(address_hash, first) do
    tt_limit = first * 2

    tokens = from(
      tt in TokenTransfer,
      where: not is_nil(tt.transaction_hash),
      where: tt.to_address_hash == ^address_hash,
      or_where: tt.from_address_hash == ^address_hash,
      select: %{
        transaction_hash: tt.transaction_hash,
        block_number: tt.block_number,
        to_address_hash: tt.to_address_hash,
        from_address_hash: tt.from_address_hash,
      },
      distinct: [desc: tt.block_number, desc: tt.transaction_hash],
      order_by: [desc: tt.block_number, desc: tt.transaction_hash, desc: tt.from_address_hash, desc: tt.to_address_hash],
      limit: ^tt_limit,
      offset: 0
    )

    from(
      tt in subquery(tokens),
      inner_join: tx in Transaction,
      on: tx.hash == tt.transaction_hash,
      inner_join: b in Block,
      on: tx.block_hash == b.hash,
      left_join: token in Token,
      on: tx.gas_currency_hash == token.contract_address_hash,
      select: %{
        transaction_hash: tt.transaction_hash,
        to_address_hash: tt.to_address_hash,
        from_address_hash: tt.from_address_hash,
        gas_used: tx.gas_used,
        gas_price: tx.gas_price,
        fee_currency: tx.gas_currency_hash,
        fee_token: fragment("coalesce(?, 'CELO')", token.symbol),
        gateway_fee: tx.gateway_fee,
        gateway_fee_recipient: tx.gas_fee_recipient_hash,
        timestamp: b.timestamp,
        input: tx.input,
        nonce: tx.nonce,
        block_number: tt.block_number
      },
      limit: ^first
    )

  end
  def token_txtransfers_query_for_address(address_hash) do
    token_txtransfers_query()
    |> where([t], t.to_address_hash == ^address_hash or t.from_address_hash == ^address_hash)
  end

  def token_txtransfers_query do
    from(
      tt in TokenTransfer,
      where: not is_nil(tt.transaction_hash),
      inner_join: tx in Transaction,
      on: tx.hash == tt.transaction_hash,
      inner_join: b in Block,
      on: tx.block_hash == b.hash,
      left_join: token in Token,
      on: tx.gas_currency_hash == token.contract_address_hash,
      select: %{
        transaction_hash: tt.transaction_hash,
        to_address_hash: tt.to_address_hash,
        from_address_hash: tt.from_address_hash,
        gas_used: tx.gas_used,
        gas_price: tx.gas_price,
        fee_currency: tx.gas_currency_hash,
        fee_token: fragment("coalesce(?, 'CELO')", token.symbol),
        gateway_fee: tx.gateway_fee,
        gateway_fee_recipient: tx.gas_fee_recipient_hash,
        timestamp: b.timestamp,
        input: tx.input,
        nonce: tx.nonce,
        block_number: tt.block_number
      },
      distinct: [desc: tt.block_number, desc: tt.transaction_hash],
      # to get the ordering from distinct clause, something is needed here too
      order_by: [asc: tx.nonce, desc: tt.from_address_hash, desc: tt.to_address_hash]
    )
  end


  def test_bad_graphql do
    {:ok,hsh} = Address.cast("0x6131a6d616a4be3737b38988847270a64bc10caa")
    token_txtransfers_query_for_address(hsh)
  end
end