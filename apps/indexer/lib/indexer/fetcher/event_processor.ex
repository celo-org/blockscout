defmodule Indexer.Fetcher.EventProcessor do
  @moduledoc "Processes logs from tracked contracts and decodes into event parameters + inserts into DB"

  use Indexer.Fetcher
  use Spandex.Decorators
  require Logger
  require Indexer.Tracer

  alias Indexer.{BufferedTask, Tracer}
  alias Indexer.Fetcher.Util

  @behaviour BufferedTask

  @defaults [
    flush_interval: :timer.seconds(3),
    max_batch_size: 500,
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
  def run(entries, state) do
    # take a batch
    # transform
    # send to import
    # emit metrics
  end


  @doc "Accepts a list of maps representing events and filters out entries that have no corresponding `ContractEventTracking` row"
  def filter_tracked_events(events) do

  end
end