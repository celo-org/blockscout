defmodule Indexer.Fetcher.UnbatchedInternalTransaction do
  @moduledoc """
  Fetches and indexes `t:Explorer.Chain.InternalTransaction.t/0` for blocks that can't be retrieved in a single rpc call.
  """

  use Indexer.Fetcher

  require Logger

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
    BufferedTask.buffer(__MODULE__, block_number, timeout)
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
    Logger.error("Fetch me a #{block_number}")
    # retrieve block
    # get list of transactions
    # fetch individually (or configurable amount idk)

#    json_rpc_named_arguments
#    |> Keyword.fetch!(:variant)
#    |> fetch_block_internal_transactions(unique_numbers, json_rpc_named_arguments)
#    |> import_internal_transaction(unique_numbers)
    :ok
  end

end