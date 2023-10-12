defmodule Explorer.Celo.SanctionCache do
  @moduledoc "A cache to manage addresses blocked for interaction"

  use GenServer

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(params \\ %{}) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(params) do
    state = Map.get(params, :initial_state, %{})

    {:ok, state, {:continue, :update_with_public_list}}
  end

  @impl true
  def handle_continue(:update_with_public_list, state) do
    new_state = Map.put(state, :list, ["0x0143008E904fEea7140c831585025bc174eB2F15", "0xtestaddresspleaseblockme"])
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_sanction_list, _from, %{list: list} = state) do
    {:reply, list, state}
  end

  def get_sanction_list() do
    GenServer.call(__MODULE__, :get_sanction_list)
  end
end