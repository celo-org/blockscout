defmodule Indexer.Prometheus.MetricsCron do
  @moduledoc """
  module to periodically retrieve and update prometheus metrics
  """
  use GenServer
  alias Explorer.Chain
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(args) do
    send(self(), :import_and_reschedule)
    {:ok, args}
  end

  @impl true
  def handle_info(:import_and_reschedule, state) do
    pending_transactions_list_from_db = Chain.pending_transactions_list()
    :telemetry.execute([:indexer, :transactions, :pending], %{value: Enum.count(pending_transactions_list_from_db)})

    last_n_blocks_count = Chain.fetch_last_n_blocks_count(1000)
    :telemetry.execute([:indexer, :blocks, :pending], %{value: 1000 - last_n_blocks_count})

    reschedule()

    {:noreply, state}
  end

  defp reschedule do
    Process.send_after(self(), :import_and_reschedule, :timer.seconds(2))
  end
end
