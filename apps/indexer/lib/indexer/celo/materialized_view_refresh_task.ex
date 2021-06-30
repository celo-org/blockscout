defmodule Indexer.Fetcher.CeloMaterializedViewRefresh do
  use GenServer

  require Logger

  alias Explorer.Repo

  @refresh_interval :timer.seconds(200)
  @timeout :timer.seconds(120)

  def start_link([init_opts, gen_server_opts]) do
    start_link(init_opts, gen_server_opts)
  end

  def start_link(init_opts, gen_server_opts) do
    GenServer.start_link(__MODULE__, init_opts, gen_server_opts)
  end

  def init(opts) do
    refresh_interval = opts[:refresh_interval] || @refresh_interval
    timeout = opts[:timeout] || @timeout

    Process.send_after(self(), :refresh_views, refresh_interval)

    {:ok, %{refresh_interval: refresh_interval, timeout: timeout}}
  end

  def handle_info(:refresh_views, %{refresh_interval: refresh_interval, timeout: timeout} = state) do
    # start telemetry

    refresh_views(timeout)

    Process.send_after(self(), :refresh_views, refresh_interval)

    {:noreply, state}
  end

  defp refresh_views(timeout) do
    # https://wiki.postgresql.org/wiki/Refresh_All_Materialized_Views

    Repo.query!("refresh materialized view celo_wallet_accounts;", timeout: timeout)
    Repo.query!("refresh materialized view celo_accumulated_rewards;", timeout: timeout)
    Repo.query!("refresh materialized view celo_attestation_stats;", timeout: timeout)

    Logger.info(fn -> "Refreshed material views." end)
  end
end
