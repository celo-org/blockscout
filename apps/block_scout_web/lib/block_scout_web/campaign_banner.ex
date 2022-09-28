defmodule BlockScoutWeb.CampaignBanner do
  @moduledoc """
  Handles providing data to show banner
  """

  use GenServer

  require Logger

  config = Application.get_env(:block_scout_web, __MODULE__)
  @backend_url Keyword.get(config, :backend_url)
  @refresh_interval Keyword.get(config, :refresh_interval, 60)

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    if not is_nil(@backend_url) and @backend_url != "" do
      Process.send_after(self(), :refresh_campaign_data, :timer.minutes(@refresh_interval))

      {:ok, refresh_campaign_data()}
    else
      {:ok, nil}
    end
  end

  @impl true
  def handle_info(:refresh_campaign_data, _) do
    Process.send_after(self(), :refresh_campaign_data, :timer.minutes(@refresh_interval))

    {:noreply, refresh_campaign_data()}
  end

  @impl GenServer
  def handle_call(:get_campaign_data, _, state) do
    {:reply, state, state}
  end

  def get_campaign_data() do
    GenServer.call(__MODULE__, :get_campaign_data)
  end

  defp refresh_campaign_data do
    Logger.info("Refreshing campaign data")

    case HTTPoison.get(@backend_url, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        case Jason.decode(body, keys: :atoms) do
          {:ok, response} ->
            case response do
              %{status: "success", data: [%{campaign: name, content: content}]} ->
                Logger.info("Campaign data refresh successful")

                %{id: name |> String.downcase() |> String.replace(" ", "-"), content: content}

              %{status: "success", data: []} ->
                Logger.info("No campaigns available")

                nil

              _ ->
                Logger.error("Unexpected response from API: #{response}")

                nil
            end

          _ ->
            Logger.error("Malformed response from API: #{body}")

            nil
        end

      _ ->
        Logger.error("Error response from API")

        nil
    end
  end
end
