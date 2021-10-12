defmodule Indexer.Fetcher.InternalTransaction.Util do
  @moduledoc """
    A utility module for common internal transaction fetching functions
  """
  require Logger
  alias Explorer.Celo.Util, as: CeloUtil
  alias Explorer.Chain
  alias Indexer.Transform.{Addresses, TokenTransfers, CeloTokenTransfers}
  alias Indexer.Fetcher.TokenBalance

  @doc "Remove child traces of errored function calls"
  def remove_failed_creations(internal_transactions_params) do
    internal_transactions_params
    |> Enum.map(fn internal_transaction_param ->
      transaction_index = internal_transaction_param[:transaction_index]
      block_number = internal_transaction_param[:block_number]

      failed_parent =
        internal_transactions_params
        |> Enum.filter(fn internal_transactions_param ->
          internal_transactions_param[:block_number] == block_number &&
            internal_transactions_param[:transaction_index] == transaction_index &&
            internal_transactions_param[:trace_address] == [] && !is_nil(internal_transactions_param[:error])
        end)
        |> Enum.at(0)

      if failed_parent do
        internal_transaction_param
        |> Map.delete(:created_contract_address_hash)
        |> Map.delete(:created_contract_code)
        |> Map.delete(:gas_used)
        |> Map.delete(:output)
        |> Map.put(:error, failed_parent[:error])
      else
        internal_transaction_param
      end
    end)
  end

  def import_first_trace(internal_transactions_params) do
    imports =
      Chain.import(%{
        internal_transactions: %{params: internal_transactions_params, with: :blockless_changeset},
        timeout: :infinity
      })

    case imports do
      {:error, step, reason, _changes_so_far} ->
        Logger.error(
          fn ->
            [
              "failed to import first trace for tx: ",
              inspect(reason)
            ]
          end,
          step: step
        )
    end
  end

  @doc "Extract CELO transfers from internal transaction traces"
  def extract_celo_native_asset_transfers(addresses, itxs) do
    with {:ok, celo_token} <- CeloUtil.get_address("GoldToken") do
      update_celo_token_balances(celo_token, addresses)
      CeloTokenTransfers.from_internal_transactions(itxs, celo_token)
    else
      _ -> []
    end
  end

  defp update_celo_token_balances(gold_token, addresses) do
    Enum.reduce(addresses, MapSet.new([]), fn
      %{fetched_coin_balance_block_number: bn, hash: hash}, acc ->
        MapSet.put(acc, %{address_hash: decode(hash), token_contract_address_hash: decode(gold_token), block_number: bn})

      _, acc ->
        acc
    end)
    |> MapSet.to_list()
    |> TokenBalance.async_fetch()
  end

  defp decode("0x" <> str) do
    %{bytes: Base.decode16!(str, case: :mixed)}
  end
end
