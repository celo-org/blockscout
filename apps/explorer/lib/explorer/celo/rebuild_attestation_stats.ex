defmodule Explorer.Celo.RebuildAttestationStats do
  alias Explorer.Repo
  require Explorer.Celo.Telemetry, as: Telemetry
  require Logger

  use Explorer.Celo.EventTypes

  def run(timeout) do
    {:ok, pid} = Task.Supervisor.start_link()

    stats = Task.Supervisor.async(pid, fn ->
      Telemetry.wrap(:rebuild_attestation_stats, fn ->
        rebuild_attestation_stats(timeout)
      end)
    end)

    Task.await(stats)
  end

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
