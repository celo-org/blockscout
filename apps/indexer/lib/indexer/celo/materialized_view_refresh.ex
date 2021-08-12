defmodule Indexer.Fetcher.CeloMaterializedViewRefresh do
  @moduledoc """
  Periodically refreshes Celo relevant Materialized Views
  """
  use GenServer

  require Logger

  alias Explorer.Repo
  require Explorer.Celo.Telemetry, as: Telemetry

  @refresh_interval :timer.seconds(150)
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
    Telemetry.wrap(:refresh_materialized_views, refresh_views(timeout))

    Process.send_after(self(), :refresh_views, refresh_interval)

    {:noreply, state}
  end

  defp refresh_views(timeout) do
    Repo.query!("refresh materialized view celo_wallet_accounts;", [], timeout: timeout)
    Repo.query!("refresh materialized view celo_accumulated_rewards;", [], timeout: timeout)

    Logger.info(fn ->
      ["Refreshed material views."]
    end)
  end

  @attestation_issuer_selected "0xaf7f470b643316cf44c1f2898328a075e7602945b4f8584f48ba4ad2d8a2ea9d"
  @attestation_completed "0x414ff2c18c092697c4b8de49f515ac44f8bebc19b24553cf58ace913a6ac639d"

  def rebuild_attestation_stats(timeout) do
    query = """
      update celo_account
      set celo_account.attestations_requested = stats.requested, celo_account.attestations_fulfilled = stats.fulfilled
      where celo_account.address = stats.address
      from (
          select r.address, r.requested, f.fulfilled
          from (
              select celo_account.address, count(*) as requested
              from logs, celo_account
              where logs.first_topic='#{@attestation_issuer_selected}'
              and logs.fourth_topic='0x000000000000000000000000'||encode(celo_account.address::bytea, 'hex') group by address
          ) r
          inner join (
              select address, count(*) as fulfilled
              from logs, celo_account
              where first_topic='#{@attestation_completed}'
              and fourth_topic='0x000000000000000000000000'||		encode(address::bytea, 'hex') group by address
          ) f
          on r.address = f.address
      ) stats;
    """

    Repo.query!(query, [], timeout: timeout)
  end
end
