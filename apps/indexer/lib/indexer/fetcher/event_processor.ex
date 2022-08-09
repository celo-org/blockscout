defmodule Indexer.Fetcher.EventProcessor do
  @moduledoc "Processes logs from tracked contracts and decodes into event parameters + inserts into DB"

  use Indexer.Fetcher
  use Spandex.Decorators
  require Logger
  alias Indexer.BufferedTask

  @behaviour BufferedTask

  @defaults [
    flush_interval: :timer.seconds(3),
    max_batch_size: 500,
    max_concurrency: 20,
    task_supervisor: Indexer.Fetcher.EventProcessor.TaskSupervisor,
    metadata: [fetcher: :event_processor]
  ]

  @impl BufferedTask
  @decorate trace(name: "fetch", resource: "Indexer.Fetcher.EventProcessor.run/2", service: :indexer, tracer: Tracer)
  def run(entries, _json_rpc_named_arguments) do
    # take a batch
    # transform
    # send to import
    # emit metrics
  end
end