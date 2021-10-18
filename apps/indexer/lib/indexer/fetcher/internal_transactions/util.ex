defmodule Indexer.Fetcher.InternalTransaction.Util do
  @moduledoc """
    A utility module for common internal transaction fetching functions
  """
  require Logger
  alias Explorer.Celo.Util, as: CeloUtil
  alias Explorer.Chain
  alias Explorer.Chain.Transaction
  alias Explorer.Chain.Cache.{Accounts, Blocks}
  alias Indexer.Transform.{Addresses, TokenTransfers, CeloTokenTransfers}
  alias Indexer.Fetcher.TokenBalance

  import Indexer.Block.Fetcher, only: [async_import_coin_balances: 2]

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

  def extract_transaction_parameters(transactions) do
    transactions
    |> Enum.map(&params(&1))
  end

  # Transforms parameters from Transaction struct to those expected by EthereumJSONRPC.fetch_internal_transactions
  defp params(%Transaction{block_number: block_number, hash: hash, index: index, block_hash: block_hash})
       when is_integer(block_number) do
    %{block_number: block_number, hash_data: to_string(hash), transaction_index: index, block_hash: block_hash}
  end


  @doc "Imports internal transactions, CELO transfers and new addresses to the DB"
  def import_internal_transaction(internal_transactions_params, unique_numbers) do
    internal_transactions_params_without_failed_creations = remove_failed_creations(internal_transactions_params)

    addresses_params =
      Addresses.extract_addresses(%{
        internal_transactions: internal_transactions_params_without_failed_creations
      })

    token_transfers =
      extract_celo_native_asset_transfers(addresses_params, internal_transactions_params_without_failed_creations)

    address_hash_to_block_number =
      Enum.into(addresses_params, %{}, fn %{fetched_coin_balance_block_number: block_number, hash: hash} ->
        {hash, block_number}
      end)

    empty_block_numbers =
      unique_numbers
      |> MapSet.new()
      |> MapSet.difference(MapSet.new(internal_transactions_params_without_failed_creations, & &1.block_number))
      |> Enum.map(&%{block_number: &1})

    internal_transactions_and_empty_block_numbers =
      internal_transactions_params_without_failed_creations ++ empty_block_numbers

    imports =
      Chain.import(%{
        token_transfers: %{params: token_transfers},
        addresses: %{params: addresses_params},
        internal_transactions: %{params: internal_transactions_and_empty_block_numbers, with: :blockless_changeset},
        timeout: :infinity
      })

    case imports do
      {:ok, imported} ->
        Accounts.drop(imported[:addreses])
        Blocks.drop_nonconsensus(imported[:remove_consensus_of_missing_transactions_blocks])

        async_import_coin_balances(imported, %{
          address_hash_to_fetched_balance_block_number: address_hash_to_block_number
        })

      {:error, step, reason, _changes_so_far} ->
        Logger.error(
          fn ->
            [
              "failed to import internal transactions for blocks: ",
              inspect(reason)
            ]
          end,
          step: step,
          error_count: Enum.count(unique_numbers)
        )

        # re-queue the de-duped entries
        {:retry, unique_numbers}
    end
  end
end
