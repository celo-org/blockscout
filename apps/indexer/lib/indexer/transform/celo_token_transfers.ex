defmodule Indexer.Transform.CeloTokenTransfers do
  @moduledoc """
  Helper functions for transforming data for Celo token transfers.
  """

  def from_internal_transactions(itxs, celo_token_contract_address) do

    %{token_transfers: transfers} = txs
    |> Enum.filter(&is_itx_celo_token_transfer/1)
    |> Enum.reduce(%{token_transfers: [], celo_token: celo_token_contract_address}, &itx_to_celo_token_transfer/2)

    transfers
  end

  defp itx_to_celo_token_transfer(tx, %{token_transfers: token_transfers, celo_token: celo_token}) do
    to_hash = Map.get(tx, :to_address_hash, nil) || Map.get(tx, :created_contract_address_hash, nil)

    token_transfer = %{
      amount: Decimal.new(tx.value),
      block_number: tx.block_number,
      block_hash: tx.block_hash,
      log_index: -(tx.index + tx.transaction_index * 1000 + 1_000_000),
      from_address_hash: tx.from_address_hash,
      to_address_hash: to_hash,
      token_contract_address_hash: celo_token,
      transaction_hash: tx.transaction_hash,
      token_type: "ERC-20"
    }

    %{token_transfers: [token_transfer | token_transfers], celo_token: celo_token}
  end

  # celo token transfer is an internal transaction with a value > 0, when it doesn't have an error field
  # or is a delegatecall
  defp is_itx_celo_token_transfer(%{error: _}), do: false
  defp is_itx_celo_token_transfer(%{call_type: "delegatecall"}), do: false
  defp is_itx_celo_token_transfer(%{value: value, index: index}) when value > 0 and index > 0, do: true
  defp is_itx_celo_token_transfer(_), do: false
end
