defmodule BlockScoutWeb.API.RPC.EpochController do
  use BlockScoutWeb, :controller

  alias Explorer.{Chain, GenericPagingOptions}
  alias Explorer.Chain.{CeloElectionRewards, CeloEpochRewards}

  @api_voter_rewards_max_page_size 100
  @api_validator_rewards_max_page_size 100
  @api_group_rewards_max_page_size 100

  def getvoterrewards(conn, params) do
    with {:address_param, {:ok, address_param}} <- fetch_address(params, "voterAddress"),
         {:address_param, group_address_param} <- get_address(params, "groupAddress"),
         {:voter_format, {:ok, voter_hash_list}} <- to_address_hash_list(address_param, :voter_format),
         {:group_format, {:ok, group_hash_list}} <- to_address_hash_list(group_address_param, :group_format),
         {:block_number_param, {:ok, from}} <- fetch_block_number(params["from"]),
         {:block_number_param, {:ok, to}} <- fetch_block_number(params["to"]),
         %{page_size: page_size, page_number: page_number} <-
           GenericPagingOptions.extract_paging_options_from_params(params, @api_voter_rewards_max_page_size),
         rewards <-
           CeloElectionRewards.get_epoch_rewards(
             voter_hash_list,
             ["voter"],
             group_hash_list,
             from,
             to,
             page_number,
             page_size
           ) do
      render(conn, :getvoterrewards, rewards: rewards)
    else
      {:address_param, :error} ->
        render(conn, :error, error: "Query parameter 'voterAddress' is required")

      {:voter_format, :error} ->
        render(conn, :error, error: "One or more voter addresses are invalid")

      {:group_format, :error} ->
        render(conn, :error, error: "One or more group addresses are invalid")

      {:block_number_param, {:error, :invalid_format}} ->
        render(conn, :error, error: "Wrong format for block number provided")

      {:block_number_param, {:error, :invalid_number}} ->
        render(conn, :error, error: "Block number must be greater than 0")
    end
  end

  def getvalidatorrewards(conn, params) do
    with {:address_param, {:ok, address_param}} <- fetch_address(params, "validatorAddress"),
         {:address_param, group_address_param} <- get_address(params, "groupAddress"),
         {:validator_format, {:ok, validator_hash_list}} <- to_address_hash_list(address_param, :validator_format),
         {:group_format, {:ok, group_hash_list}} <- to_address_hash_list(group_address_param, :group_format),
         {:block_number_param, {:ok, from}} <- fetch_block_number(params["from"]),
         {:block_number_param, {:ok, to}} <- fetch_block_number(params["to"]),
         %{page_size: page_size, page_number: page_number} <-
           GenericPagingOptions.extract_paging_options_from_params(params, @api_validator_rewards_max_page_size),
         rewards <-
           CeloElectionRewards.get_epoch_rewards(
             validator_hash_list,
             ["validator"],
             group_hash_list,
             from,
             to,
             page_number,
             page_size
           ) do
      render(conn, :getvalidatorrewards, rewards: rewards)
    else
      {:address_param, :error} ->
        render(conn, :error, error: "Query parameter 'validatorAddress' is required")

      {:validator_format, :error} ->
        render(conn, :error, error: "One or more validator addresses are invalid")

      {:group_format, :error} ->
        render(conn, :error, error: "One or more group addresses are invalid")

      {:block_number_param, {:error, :invalid_format}} ->
        render(conn, :error, error: "Wrong format for block number provided")

      {:block_number_param, {:error, :invalid_number}} ->
        render(conn, :error, error: "Block number must be greater than 0")
    end
  end

  def getgrouprewards(conn, params) do
    with {:address_param, {:ok, group_address_param}} <- fetch_address(params, "groupAddress"),
         {:address_param, validator_address_param} <- get_address(params, "validatorAddress"),
         {:group_format, {:ok, group_hash_list}} <- to_address_hash_list(group_address_param, :group_format),
         {:validator_format, {:ok, validator_hash_list}} <-
           to_address_hash_list(validator_address_param, :validator_format),
         {:block_number_param, {:ok, from}} <- fetch_block_number(params["from"]),
         {:block_number_param, {:ok, to}} <- fetch_block_number(params["to"]),
         %{page_size: page_size, page_number: page_number} <-
           GenericPagingOptions.extract_paging_options_from_params(params, @api_group_rewards_max_page_size),
         rewards <-
           CeloElectionRewards.get_epoch_rewards(
             group_hash_list,
             ["group"],
             validator_hash_list,
             from,
             to,
             page_number,
             page_size
           ) do
      render(conn, :getgrouprewards, rewards: rewards)
    else
      {:address_param, :error} ->
        render(conn, :error, error: "Query parameter 'groupAddress' is required")

      {:validator_format, :error} ->
        render(conn, :error, error: "One or more validator addresses are invalid")

      {:group_format, :error} ->
        render(conn, :error, error: "One or more group addresses are invalid")

      {:block_number_param, {:error, :invalid_format}} ->
        render(conn, :error, error: "Wrong format for block number provided")

      {:block_number_param, {:error, :invalid_number}} ->
        render(conn, :error, error: "Block number must be greater than 0")
    end
  end

  def getepoch(conn, params) do
    with {:block_number_param, {:ok, epoch_number}} <- get_block_number(params["epochNumber"]),
         epoch_rewards <-
           CeloEpochRewards.get_celo_epoch_rewards_for_epoch_number(epoch_number) do
      render(conn, :getepoch, epoch: epoch_rewards)
    else
      {:block_number_param, nil} ->
        render(conn, :error, error: "Query parameter 'epochNumber' is required")

      {:block_number_param, {:error, :invalid_format}} ->
        render(conn, :error, error: "Wrong format for epoch number provided")

      {:block_number_param, {:error, :invalid_number}} ->
        render(conn, :error, error: "Epoch number must be greater than 0")
    end
  end

  defp get_address(params, key), do: {:address_param, Map.get(params, key)}

  defp fetch_address(params, key), do: {:address_param, Map.fetch(params, key)}

  defp to_address_hash_list(nil, key), do: {key, {:ok, []}}

  defp to_address_hash_list(address_hashes_string, key) do
    cast_hashes =
      address_hashes_string
      |> split_address_input_string
      |> Enum.map(fn str ->
        case Chain.string_to_address_hash(str) do
          {:ok, hash} -> hash
          _ -> false
        end
      end)

    if Enum.all?(cast_hashes) do
      {key, {:ok, cast_hashes}}
    else
      {key, :error}
    end
  end

  defp split_address_input_string(address_input_string) do
    address_input_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end

  defp fetch_block_number(nil), do: {:block_number_param, {:ok, nil}}

  defp fetch_block_number(block_number) do
    {:block_number_param,
     case Integer.parse(block_number) do
       {int, ""} when int < 1 -> {:error, :invalid_number}
       {int, ""} -> {:ok, int}
       _ -> {:error, :invalid_format}
     end}
  end

  defp get_block_number(nil), do: {:block_number_param, nil}
  defp get_block_number(block_number_param), do: fetch_block_number(block_number_param)
end
