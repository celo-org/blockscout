defmodule BlockScoutWeb.API.RPC.RewardController do
  use BlockScoutWeb, :controller

  alias Explorer.Celo.{ValidatorGroupRewards, ValidatorRewards, VoterRewards, VoterRewardsForGroup}
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
    end
  end

  def getvoterrewards(conn, params) do
    with {:voter_address_param, {:ok, voter_address_param}} <- fetch_address(params, "voterAddress"),
         {:voter_format, {:ok, voter_address_hash}} <- to_address_hash(voter_address_param, "voterAddress"),
         {:date_param, {:ok, from, _}} <- fetch_date(params["from"]),
         {:date_param, {:ok, to, _}} <- fetch_date(params["to"]),
         {:ok, rewards} <- VoterRewards.calculate(voter_address_hash, from, to) do
      render(conn, :getvoterrewards, rewards: rewards)
    else
      {:voter_address_param, :error} ->
        render(conn, :error, error: "Query parameter 'voterAddress' is required")

      {:voter_format, :error} ->
        render(conn, :error, error: "Invalid voter address hash")

      {:date_param, {:error, _}} ->
        render(conn, :error, error: "Please only ISO 8601 formatted dates")
    end
  end

  def getvalidatorrewards(conn, params) do
    with {:validator_address_param, {:ok, validator_address_param}} <- fetch_address(params, "validatorAddress"),
         {:validator_format, {:ok, validator_address_hash}} <-
           to_address_hash(validator_address_param, "validatorAddress"),
         {:date_param, {:ok, from, _}} <- fetch_date(params["from"]),
         {:date_param, {:ok, to, _}} <- fetch_date(params["to"]),
         {:ok, rewards} <- ValidatorRewards.calculate(validator_address_hash, from, to) do
      render(conn, :getvalidatorrewards, rewards: rewards)
    else
      {:validator_address_param, :error} ->
        render(conn, :error, error: "Query parameter 'validatorAddress' is required")

      {:validator_format, :error} ->
        render(conn, :error, error: "Invalid validator address hash")

      {:date_param, {:error, _}} ->
        render(conn, :error, error: "Please only ISO 8601 formatted dates")
    end
  end

  def getvalidatorgrouprewards(conn, params) do
    with {:group_address_param, {:ok, group_address_param}} <- fetch_address(params, "groupAddress"),
         {:group_format, {:ok, group_address_hash}} <- to_address_hash(group_address_param, "groupAddress"),
         {:date_param, {:ok, from, _}} <- fetch_date(params["from"]),
         {:date_param, {:ok, to, _}} <- fetch_date(params["to"]),
         {:ok, rewards} <- ValidatorGroupRewards.calculate(group_address_hash, from, to) do
      render(conn, :getvalidatorgrouprewards, rewards: rewards)
    else
      {:group_address_param, :error} ->
        render(conn, :error, error: "Query parameter 'groupAddress' is required")

      {:group_format, :error} ->
        render(conn, :error, error: "Invalid group address hash")

      {:date_param, {:error, _}} ->
        render(conn, :error, error: "Please only ISO 8601 formatted dates")
    end
  end

  def getvotersrewards(conn, params) do
    with {:voter_address_param, {:ok, voter_address_param}} <- fetch_address(params, "voterAddresses"),
         {:voter_format, {:ok, voter_address_hashes}} <- to_address_hashes(voter_address_param, "voterAddresses"),
         {:date_param, {:ok, from, _}} <- fetch_date(params["from"]),
         {:date_param, {:ok, to, _}} <- fetch_date(params["to"]),
         {:ok, rewards} <- VoterRewards.calculate_multiple_accounts(voter_address_hashes, from, to) do
      render(conn, :getvotersrewards, rewards: rewards)
    else
      {:voter_address_param, :error} ->
        render(conn, :error, error: "Query parameter 'voterAddresses' is required")

      {:voter_format, :error} ->
        render(conn, :error, error: "One or more voter addresses are invalid")

      {:date_param, {:error, _}} ->
        render(conn, :error, error: "Please only ISO 8601 formatted dates")
    end
  end

  def getvalidatorsrewards(conn, params) do
    with {:validator_address_param, {:ok, validator_address_param}} <- fetch_address(params, "validatorAddresses"),
         {:validator_format, {:ok, validator_address_hashes}} <-
           to_address_hashes(validator_address_param, "validatorAddresses"),
         {:date_param, {:ok, from, _}} <- fetch_date(params["from"]),
         {:date_param, {:ok, to, _}} <- fetch_date(params["to"]),
         {:ok, rewards} <- ValidatorRewards.calculate_multiple_accounts(validator_address_hashes, from, to) do
      render(conn, :getvalidatorsrewards, rewards: rewards)
    else
      {:validator_address_param, :error} ->
        render(conn, :error, error: "Query parameter 'validatorAddresses' is required")

      {:validator_format, :error} ->
        render(conn, :error, error: "One or more validator addresses are invalid")

      {:date_param, {:error, _}} ->
        render(conn, :error, error: "Please only ISO 8601 formatted dates")
    end
  end

  def getvalidatorgroupsrewards(conn, params) do
    with {:group_address_param, {:ok, group_addresses_param}} <- fetch_address(params, "groupAddresses"),
         {:group_format, {:ok, group_address_hashes}} <- to_address_hashes(group_addresses_param, "groupAddresses"),
         {:date_param, {:ok, from, _}} <- fetch_date(params["from"]),
         {:date_param, {:ok, to, _}} <- fetch_date(params["to"]),
         {:ok, rewards} <- ValidatorGroupRewards.calculate_multiple_accounts(group_address_hashes, from, to) do
      render(conn, :getvalidatorgroupsrewards, rewards: rewards)
    else
      {:group_address_param, :error} ->
        render(conn, :error, error: "Query parameter 'groupAddresses' is required")

      {:group_format, :error} ->
        render(conn, :error, error: "One or more group addresses are invalid")

      {:date_param, {:error, _}} ->
        render(conn, :error, error: "Please only ISO 8601 formatted dates")
    end
  end

  defp fetch_address(params, key) when key == "voterAddress" or key == "voterAddresses" do
    {:voter_address_param, Map.fetch(params, key)}
  end

  defp fetch_address(params, key) when key == "groupAddress" or key == "groupAddresses" do
    {:group_address_param, Map.fetch(params, key)}
  end

  defp fetch_address(params, key) when key == "validatorAddress" or key == "validatorAddresses" do
    {:validator_address_param, Map.fetch(params, key)}
  end

  defp fetch_date(date) do
    case date do
      nil -> {:date_param, {:ok, nil, nil}}
      date -> {:date_param, DateTime.from_iso8601(date)}
    end
  end

  defp to_address_hash(address_hash_string, key) when key == "voterAddress" do
    {:voter_format, Chain.string_to_address_hash(address_hash_string)}
  end

  defp to_address_hash(address_hash_string, key) when key == "groupAddress" do
    {:group_format, Chain.string_to_address_hash(address_hash_string)}
  end

  defp to_address_hash(address_hash_string, key) when key == "validatorAddress" do
    {:validator_format, Chain.string_to_address_hash(address_hash_string)}
  end

  defp to_address_hashes(address_hashes_string, key) when key == "voterAddresses" do
    uncast_hashes = split_address_input_string(address_hashes_string)

    cast_hashes = Enum.map(uncast_hashes, &Chain.string_to_address_hash/1)

    if Enum.all?(cast_hashes, fn
         {:ok, _} -> true
         _ -> false
       end) do
      {:voter_format, {:ok, Enum.map(cast_hashes, fn {:ok, hash} -> hash end)}}
    else
      {:voter_format, :error}
    end
  end

  defp to_address_hashes(address_hashes_string, key) when key == "validatorAddresses" do
    uncast_hashes = split_address_input_string(address_hashes_string)

    cast_hashes = Enum.map(uncast_hashes, &Chain.string_to_address_hash/1)

    if Enum.all?(cast_hashes, fn
      {:ok, _} -> true
      _ -> false
    end) do
      {:validator_format, {:ok, Enum.map(cast_hashes, fn {:ok, hash} -> hash end)}}
    else
      {:validator_format, :error}
    end
  end

  defp to_address_hashes(address_hashes_string, key) when key == "groupAddresses" do
    uncast_hashes = split_address_input_string(address_hashes_string)

    cast_hashes = Enum.map(uncast_hashes, &Chain.string_to_address_hash/1)

    if Enum.all?(cast_hashes, fn
      {:ok, _} -> true
      _ -> false
    end) do
      {:group_format, {:ok, Enum.map(cast_hashes, fn {:ok, hash} -> hash end)}}
    else
      {:group_format, :error}
    end
  end

  defp split_address_input_string(address_input_string) do
    address_input_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end
end
