defmodule BlockScoutWeb.API.RPC.RewardController do
  use BlockScoutWeb, :controller

  alias Explorer.Celo.VoterRewardsForGroup
  alias Explorer.Chain

  def getvoterrewardsforgroup(conn, params) do
    with {:voter_address_param, {:ok, voter_address_param}} <- fetch_address(params, "voterAddress"),
         {:group_address_param, {:ok, group_address_param}} <- fetch_address(params, "groupAddress"),
         {:voter_format, {:ok, voter_address_hash}} <- to_address_hash(voter_address_param, "voterAddress"),
         {:group_format, {:ok, group_address_hash}} <- to_address_hash(group_address_param, "groupAddress"),
         {:ok, rewards} <- VoterRewardsForGroup.calculate(voter_address_hash, group_address_hash) do
      render(conn, :getvoterrewardsforgroup, rewards: rewards)
    else
      {:voter_address_param, :error} ->
        render(conn, :error, error: "Query parameter 'voterAddress' is required")

      {:group_address_param, :error} ->
        render(conn, :error, error: "Query parameter 'groupAddress' is required")

      {:voter_format, :error} ->
        render(conn, :error, error: "Invalid voter address hash")

      {:group_format, :error} ->
        render(conn, :error, error: "Invalid group address hash")

      {:error, :not_found} ->
        render(conn, :error, error: "Voter or group address does not exist")
    end
  end

  defp fetch_address(params, key) when key == "voterAddress" do
    {:voter_address_param, Map.fetch(params, key)}
  end

  defp fetch_address(params, key) when key == "groupAddress" do
    {:group_address_param, Map.fetch(params, key)}
  end

  defp to_address_hash(address_hash_string, key) when key == "voterAddress" do
    {:voter_format, Chain.string_to_address_hash(address_hash_string)}
  end

  defp to_address_hash(address_hash_string, key) when key == "groupAddress" do
    {:group_format, Chain.string_to_address_hash(address_hash_string)}
  end
end
