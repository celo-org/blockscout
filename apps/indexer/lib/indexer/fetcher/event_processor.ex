defmodule Indexer.Fetcher.EventProcessor do
  @moduledoc "Processes logs from tracked contracts and decodes into event parameters + inserts into DB"

  use Indexer.Fetcher
  use Spandex.Decorators
  require Logger
  require Indexer.Tracer

  alias Explorer.Celo.Events.Transformer
  alias Explorer.Chain
  alias Indexer.{BufferedTask, Tracer}
  alias Indexer.Celo.TrackedEventCache
  alias Indexer.Fetcher.Util

  @behaviour BufferedTask

  @defaults [
    flush_interval: :timer.seconds(3),
    max_batch_size: 1,
    max_concurrency: 20,
    task_supervisor: Indexer.Fetcher.EventProcessor.TaskSupervisor,
    metadata: [fetcher: :event_processor]
  ]

  @impl BufferedTask
  def init(initial, _reducer, _) do

    initial
  end

  @doc false
  def child_spec([init_options, gen_server_options]) do
    Util.default_child_spec(init_options, gen_server_options, __MODULE__)
  end

  @impl BufferedTask
  @decorate trace(name: "fetch", resource: "Indexer.Fetcher.EventProcessor.run/2", service: :indexer, tracer: Tracer)
  def run([{logs, function_selector}] = batch, state) do
    decoded = logs
    |> Enum.map(fn log ->
      function_selector
      |> Transformer.decode_event(log)
      |> add_meta_properties(log, function_selector)
    end)

    imported = Chain.import(
      %{tracked_events: decoded, timeout: :infinity}
    )

    case imported do
      {:ok, events} ->
        :ok
      {:error, step, reason, _changes} ->
        Logger.error("Failed to import tracked events  #{step} - #{inspect(reason)}")
        {:retry, batch}
    end
  end

  def add_meta_properties(event_params, log, function_selector) do
    %{
      params: event_params,
      name: function_selector.function,
      address_hash: log.address_hash,
      transaction_hash: log.transaction_hash,
      block_number: log.block_number,
      log_index: log.index
    }
  end

  @doc "Accepts a list of maps representing events and filters out entries that have no corresponding `ContractEventTracking` row"
  def enqueue_logs(events) do
    events
    |> TrackedEventCache.batch_events()
    |> then(&BufferedTask.buffer(__MODULE__, &1))
  end
end