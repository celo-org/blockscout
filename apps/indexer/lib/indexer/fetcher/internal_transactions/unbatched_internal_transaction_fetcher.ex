defmodule Indexer.Fetcher.UnbatchedInternalTransaction do
  @moduledoc """
  Fetches and indexes `t:Explorer.Chain.InternalTransaction.t/0` for blocks that can't be retrieved in a single rpc call.
  """

  use Indexer.Fetcher

  require Logger
  alias Explorer.Chain
  alias Indexer.BufferedTask
  alias Indexer.Fetcher.InternalTransaction.Util

  @behaviour BufferedTask

  @max_batch_size 1
  @max_concurrency 3
  @defaults [
    flush_interval: :timer.seconds(3),
    max_concurrency: @max_concurrency,
    max_batch_size: @max_batch_size,
    poll: false,
    task_supervisor: Indexer.Fetcher.UnbatchedInternalTransaction.TaskSupervisor,
    metadata: [fetcher: :unbatched_internal_transaction]
  ]

  @spec async_fetch(Number) :: :ok
  def async_fetch(block_number, timeout \\ 5000) when is_number(block_number) do
    Logger.error("Buffering #{block_number}")
    BufferedTask.buffer(__MODULE__, [block_number], timeout)
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
  def init(initial, _reducer, _json_rpc_named_arguments) do
    initial
  end

  @impl BufferedTask
  def run([block_number], json_rpc_named_arguments) do
    block = Chain.number_to_any_block(block_number)

    block_number
    |> Chain.get_transactions_of_block_number()
    |> Util.extract_transaction_parameters()
    |> fetch_internal_transactions(block, json_rpc_named_arguments)
    |> import_internal_transaction([block_number])

    # retrieve block
    # get list of transactions
    # fetch individually (or configurable amount idk)

    #    json_rpc_named_arguments
    #    |> Keyword.fetch!(:variant)
    #    |> fetch_block_internal_transactions(unique_numbers, json_rpc_named_arguments)
    #    |> import_internal_transaction(unique_numbers)
    :ok
  end


  def fetch_internal_transactions(transactions, block, _jsonrpc_args, 0) do
    transactions
    |> Enum.map(fn tx ->
      {{:error, "Retry limit exceeded"}, block, tx}
    end)
  end

  def fetch_internal_transactions(transactions, block, jsonrpc_args, retry_count \\ 3) do
    fetch_results = transactions
    |> Enum.map(fn tx ->
      case EthereumJSONRPC.fetch_internal_transactions([tx], jsonrpc_args) do
        {:ok, res} ->
          {{:ok, res}, 1, block}

        {:error, reason} ->
          {{:error, reason}, block, tx}
      end
    end)

    # reduce results to a tuple of {failed_tx_list, succeeded_fetch_result_list}
    {failed, success} = fetch_results
                      |> Enum.reduce({[],[]}, fn
      {{:error, _} ,_, tx}, {f, s} -> {[tx | f], s}
      t = {{:ok, _} ,_, _}, {f, s} -> {f, [t | s]}
    end)

    # retry failures and return
    if Enum.count(failed) > 0 do
      success ++ fetch_internal_transactions(failed, block, jsonrpc_args, retry_count - 1)
    else
      success
    end
  end
end