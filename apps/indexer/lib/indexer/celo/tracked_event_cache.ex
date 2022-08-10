defmodule Indexer.Celo.TrackedEventCache do
  @moduledoc "Maintains ets tables representing events that are to be tracked + functions to filter tracked events"

  use GenServer

  require Logger
  import Ecto.Query

  alias Explorer.Chain.Celo.ContractEventTracking
  alias Explorer.Repo
  require Explorer.Celo.Telemetry, as: Telemetry

  def start_link([init_opts, gen_server_opts]) do
    start_link(init_opts, gen_server_opts)
  end

  def start_link(init_opts, gen_server_opts) do
    GenServer.start_link(__MODULE__, init_opts, gen_server_opts)
  end

  def init(opts) do
    state = %{
      table_ref: nil
    }

    {:ok, state, {:continue, :populate_cache}}
  end

  def handle_continue(:populate_cache, state) do
    #create ets table
    cache_table = :ets.new(__MODULE__, [:set, :protected, :named_table])

    cache_table |> build_cache()

    {:noreply, %{state | table_ref: cache_table}}
  end

  defp build_cache(table_ref) do
    query = from(
      et in ContractEventTracking,
      where: et.enabled == true,
      preload: [:smart_contract]
    )

    cache_values = query
                   |> Repo.all()
                   |> Enum.map(fn cet = %ContractEventTracking{} -> cet |> event_id() end)

    table_ref |> :ets.delete_all_objects()

    cache_values
    |> Enum.each(fn event_topic_and_contract_address ->
      :ets.insert(table_ref, {event_topic_and_contract_address, true})
    end)
  end

  def filter_tracked(events) when is_list(events) do
    events
    |> Enum.filter(&tracked_event?/1)
  end

  defp tracked_event?(event) do
    :ets.lookup(__MODULE__, event_id(event)) != []
  end

  # calculating event id as a tuple of {event_topic, contract_address}
  defp event_id(%{topic: topic, smart_contract: sc}) do
    {topic, sc.address_hash |> to_string()}
  end

  defp event_id(%{first_topic: topic, address_hash: address_hash}) do
    {topic, address_hash |> to_string()}
  end
end