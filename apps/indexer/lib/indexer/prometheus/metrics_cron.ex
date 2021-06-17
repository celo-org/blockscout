defmodule Indexer.Prometheus.MetricsCron do
  @moduledoc """
  Periodically retrieves and updates prometheus metrics
  """
  use GenServer
  alias Explorer.Chain
  alias Explorer.Counters.AverageBlockTime
  alias Indexer.Prometheus.{ResponseETS, RPCInstrumenter}
  alias Timex.Duration

  require DateTime
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

    {last_n_blocks_count, last_block_timestamp, last_block_number, average_gas_used} = Chain.metrics_fetcher(1000)

    :telemetry.execute([:indexer, :blocks, :pending], %{value: 1000 - last_n_blocks_count})
    :telemetry.execute([:indexer, :tokens, :average_gas], %{value: average_gas_used})

    :telemetry.execute([:indexer, :blocks, :last_block_age], %{
      value: DateTime.diff(DateTime.utc_now(), last_block_timestamp)
    })

    :telemetry.execute([:indexer, :blocks, :last_block_number], %{value: last_block_number})

    average_block_time = AverageBlockTime.average_block_time()
    :telemetry.execute([:indexer, :blocks, :average_time], %{value: Duration.to_seconds(average_block_time)})

    number_of_locks = Chain.fetch_number_of_locks()
    :telemetry.execute([:indexer, :db, :locks], %{value: number_of_locks})

    number_of_dead_locks = Chain.fetch_number_of_dead_locks()
    :telemetry.execute([:indexer, :db, :deadlocks], %{value: number_of_dead_locks})

    longest_query_duration = Chain.fetch_name_and_duration_of_longest_query()
    :telemetry.execute([:indexer, :db, :longest_query_duration], %{value: longest_query_duration.seconds})

    response_times = ResponseETS.get_all()

    response_times
    |> Enum.filter(&Map.has_key?(elem(&1, 1), :finish))
    |> Enum.map(&elem(&1, 0))
    |> Enum.each(&calculate_and_add_rpc_response_metrics(&1, :proplists.get_all_values(&1, response_times)))

    total_transaction_count = Chain.transaction_estimated_count()
    :telemetry.execute([:indexer, :transactions, :total], %{value: total_transaction_count})

    total_address_count = Chain.address_estimated_count()
    :telemetry.execute([:indexer, :tokens, :address_count], %{value: total_address_count})

    with total_supply when not is_nil(total_supply) <- Chain.total_supply() do
      :telemetry.execute([:indexer, :tokens, :total_supply], %{value: Decimal.to_float(total_supply)})
    end

    repeat()

    {:noreply, state}
  end

  defp calculate_and_add_rpc_response_metrics(id, req_times) do
    start = Enum.at(req_times, 0)
    finish = Enum.at(req_times, 1)

    RPCInstrumenter.instrument(%{
      time: Map.get(finish, :finish) - Map.get(start, :start),
      method: Map.get(start, :method)
    })

    ResponseETS.delete(id)
  end

  defp repeat do
    Process.send_after(self(), :import_and_reschedule, :timer.seconds(2))
  end
end
