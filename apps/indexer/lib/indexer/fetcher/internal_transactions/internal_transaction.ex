defmodule Indexer.Fetcher.InternalTransaction do
  @moduledoc """
  Fetches and indexes `t:Explorer.Chain.InternalTransaction.t/0`.

  See `async_fetch/1` for details on configuring limits.
  """

  use Indexer.Fetcher
  use Spandex.Decorators

  require Logger

  import Indexer.Block.Fetcher, only: [async_import_coin_balances: 2]

  alias Explorer.Chain
  alias Explorer.Chain.{Block, Transaction}
  alias Explorer.Chain.Cache.{Accounts, Blocks}
  alias Indexer.{BufferedTask, Tracer}
  alias Indexer.Transform.Addresses
  alias Indexer.Fetcher.TokenBalance
  alias Indexer.Fetcher.InternalTransaction.Util
  alias Indexer.Fetcher.UnbatchedInternalTransaction

  @behaviour BufferedTask

  @max_batch_size 20
  @max_concurrency 8
  @defaults [
    flush_interval: :timer.seconds(3),
    poll_interval: :timer.seconds(3),
    max_concurrency: @max_concurrency,
    max_batch_size: @max_batch_size,
    poll: true,
    task_supervisor: Indexer.Fetcher.InternalTransaction.TaskSupervisor,
    metadata: [fetcher: :internal_transaction]
  ]

  @doc """
  Asynchronously fetches internal transactions.

  ## Limiting Upstream Load

  Internal transactions are an expensive upstream operation. The number of
  results to fetch is configured by `@max_batch_size` and represents the number
  of transaction hashes to request internal transactions in a single JSONRPC
  request. Defaults to `#{@max_batch_size}`.

  The `@max_concurrency` attribute configures the  number of concurrent requests
  of `@max_batch_size` to allow against the JSONRPC. Defaults to `#{@max_concurrency}`.

  *Note*: The internal transactions for individual transactions cannot be paginated,
  so the total number of internal transactions that could be produced is unknown.
  """
  @spec async_fetch([Block.block_number()]) :: :ok
  def async_fetch(block_numbers, timeout \\ 5000) when is_list(block_numbers) do
    BufferedTask.buffer(__MODULE__, block_numbers, timeout)
  end

  @doc false
  def child_spec([init_options, gen_server_options]) do
    {state, mergeable_init_options} = Keyword.pop(init_options, :json_rpc_named_arguments)

    unless state do
      raise ArgumentError,
            ":json_rpc_named_arguments must be provided to `#{__MODULE__}.child_spec " <>
              "to allow for json_rpc calls when running."
    end

    merged_init_opts =
      @defaults
      |> Keyword.merge(mergeable_init_options)
      |> Keyword.put(:state, state)

    Supervisor.child_spec({BufferedTask, [{__MODULE__, merged_init_opts}, gen_server_options]}, id: __MODULE__)
  end

  @impl BufferedTask
  def init(initial, reducer, _json_rpc_named_arguments) do
    {:ok, final} =
      Chain.stream_blocks_with_unfetched_internal_transactions(initial, fn block_number, acc ->
        reducer.(block_number, acc)
      end)

    final
  end

  @impl BufferedTask
  @decorate trace(
              name: "fetch",
              resource: "Indexer.Fetcher.InternalTransaction.run/2",
              service: :indexer,
              tracer: Tracer
            )
  def run(block_numbers, json_rpc_named_arguments) do
    unique_numbers = Enum.uniq(block_numbers)

    Logger.metadata(count: Enum.count(unique_numbers))
    Logger.debug("fetching internal transactions for blocks")

    json_rpc_named_arguments
    |> Keyword.fetch!(:variant)
    |> fetch_block_internal_transactions(unique_numbers, json_rpc_named_arguments)
    |> import_internal_transaction(unique_numbers)
  end

  defp fetch_block_internal_transactions(rpc_variant, unique_numbers, json_rpc_named_arguments)
       when rpc_variant in [EthereumJSONRPC.Parity, EthereumJSONRPC.Besu] do
    EthereumJSONRPC.fetch_block_internal_transactions(unique_numbers, json_rpc_named_arguments)
  end

  defp fetch_block_internal_transactions(_variant, unique_numbers, json_rpc_named_arguments) do
    try do
      fetch_block_internal_transactions_by_transactions(unique_numbers, json_rpc_named_arguments)
    rescue
      error ->
        {:error, error}
    end
  end

  @doc "Fetch internal transactions individually for rpcvariants that don't support a fetch by block method (e.g. Geth)"
  defp fetch_block_internal_transactions_by_transactions(unique_numbers, json_rpc_named_arguments) do
    Enum.reduce(unique_numbers, {:ok, []}, fn
      block_number, {:ok, acc_list} ->
        block = Chain.number_to_any_block(block_number)

        block_number
        |> Chain.get_transactions_of_block_number()
        |> Util.extract_transaction_parameters()
        |> perform_internal_transaction_fetch(block, json_rpc_named_arguments)
        |> handle_transaction_fetch_results(block_number, acc_list)

      _, error_or_ignore ->
        error_or_ignore
    end)
  end


  defp perform_internal_transaction_fetch([], block, _jsonrpc_named_arguments), do: {{:ok, []}, 0, block}

  defp perform_internal_transaction_fetch(transactions, block, jsonrpc_named_arguments) do
    case EthereumJSONRPC.fetch_internal_transactions(transactions, jsonrpc_named_arguments) do
      {:ok, res} ->
        {{:ok, res}, Enum.count(transactions), block}

      {:error, reason} ->
        {:error, reason, block}
    end
  end

  defp handle_transaction_fetch_results(
         {{:ok, internal_transactions}, num, {:ok, %{gas_used: used_gas, hash: block_hash}}},
         block_number,
         acc
       ) do
    Logger.debug(
      "Found #{Enum.count(internal_transactions)} internal tx for block #{block_number} had txs: #{num} used gas #{
        used_gas
      }"
    )

    case check_db(num, Decimal.new(used_gas)) do
      {:ok} ->
        {:ok, add_block_hash(block_hash, internal_transactions) ++ acc}

      {:error, :block_not_indexed_properly} ->
        Logger.error("Block #{block_number} not indexed properly")
        {:ok, acc}
    end
  end

  defp handle_transaction_fetch_results({:error, e, _block}, block_number, acc) do
    Logger.error("failed to fetch internal transactions for block #{block_number} - error=#{inspect(e)}")

    if e == :closed do
      UnbatchedInternalTransaction.async_fetch(block_number)
    end

    {:ok, acc}
  end

  defp check_db(num, used_gas) do
    if num != 0 || Decimal.to_integer(used_gas) == 0 do
      {:ok}
    else
      {:error, :block_not_indexed_properly}
    end
  end

  # block_hash is required for CeloTokenTransfers.from_internal_transactions
  defp add_block_hash(block_hash, internal_transactions) do
    Enum.map(internal_transactions, fn a -> Map.put(a, :block_hash, block_hash) end)
  end

  defp import_internal_transaction(:ignore, _unique_numbers), do: :ok

  defp import_internal_transaction({:error, reason}, unique_numbers) do
    block_numbers = unique_numbers |> inspect(charlists: :as_lists)
    unique_numbers_count = unique_numbers |> Enum.count()

    Logger.debug(
      "failed to fetch internal transactions for #{unique_numbers_count} blocks: #{block_numbers} reason: #{
        inspect(reason)
      }",
      error_count: unique_numbers_count
    )

    :ok
  end

  defp import_internal_transaction({:ok, internal_transactions_params}, unique_numbers) do
    internal_transactions_params_without_failed_creations = Util.remove_failed_creations(internal_transactions_params)

    addresses_params =
      Addresses.extract_addresses(%{
        internal_transactions: internal_transactions_params_without_failed_creations
      })

    token_transfers =
      Util.extract_celo_native_asset_transfers(addresses_params, internal_transactions_params_without_failed_creations)

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
