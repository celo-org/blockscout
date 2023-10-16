defmodule Explorer.Celo.SanctionCache do
  @moduledoc "A cache to manage addresses blocked for interaction"

  use GenServer
  require Logger

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(params \\ %{}) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(params) do
    state = Map.get(params, :initial_state, %{list: [], refresh: :timer.minutes(60)})

    {:ok, state, {:continue, :update_with_public_list}}
  end

  @impl true
  def handle_continue(:update_with_public_list, %{refresh: refresh_time} = state) do
    sanction_list = fetch_list()

    Process.send_after(self, :refresh, refresh_time)

    {:noreply, %{state | list: sanction_list}}
  end

  def fetch_list() do
    sanctions_url = :explorer
                    |> Application.get_env(:celo_sanctions)
                    |> Keyword.get(:url, "https://celo-org.github.io/compliance/ofac.sanctions.json")

    Logger.info("Fetching sanctioned address list from #{sanctions_url}")

    {:ok, response} = case HTTPoison.get(sanctions_url, [], follow_redirect: true, timeout: 5_000) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, body}

      e ->
        {:error, inspect(e)}
    end

    sanction_list = response |> Jason.decode!()

    Logger.info("Retrieved #{length(sanction_list)} sanctioned addresses (md5 #{hash_list(sanction_list)}")

    sanction_list
  end
  @doc "printable md5 hash of list contents to assert changed values"
  def hash_list(list) do
    :crypto.hash(:md5, :erlang.term_to_binary(list)) |> Base.encode16()
  end

  @impl true
  def handle_call(:get_sanction_list, _from, %{list: list} = state) do
    {:reply, list, state}
  end

  @impl true
  def handle_cast({:add_address, address}, %{list: list} = state) do
    {:noreply, %{state | list: [address | list]}}
  end

  @impl true
  def handle_info(:refresh, state) do
    {:noreply, state, {:continue, :update_with_public_list}}
  end

  def get_sanction_list() do
    GenServer.call(__MODULE__, :get_sanction_list)
  end

  def add_address(address) do
    GenServer.cast(__MODULE__, {:add_address, address})
  end
end