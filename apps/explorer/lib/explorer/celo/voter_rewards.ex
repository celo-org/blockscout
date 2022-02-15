defmodule Explorer.Celo.VoterRewards do
  @moduledoc """
    Module responsible for calculating a voter's rewards for all groups the voter has voted for.
  """

  import Ecto.Query,
    only: [
      from: 2
    ]

  alias Explorer.Celo.{ContractEvents, Events, Util}
  alias Explorer.Chain.{Block, CeloContractEvent, CeloValidatorGroupVotes, Wei}
  alias Explorer.Repo

  alias ContractEvents.{Common, Election}

  alias Election.{
    EpochRewardsDistributedToVotersEvent,
    ValidatorGroupActiveVoteRevokedEvent,
    ValidatorGroupVoteActivatedEvent
  }

  def calculate(voter_address_hash, from_date, to_date) do
    from_date =
      case from_date do
        nil -> ~U[2020-04-22 16:00:00.000000Z]
        from_date -> from_date
      end

    to_date =
      case to_date do
        nil -> DateTime.utc_now()
        to_date -> to_date
      end

    voter_rewards_for_group = Application.get_env(:explorer, :voter_rewards_for_group)
    validator_group_vote_activated = ValidatorGroupVoteActivatedEvent.name()

    query =
      from(event in CeloContractEvent,
        inner_join: block in Block,
        on: event.block_hash == block.hash,
        select: json_extract_path(event.params, ["group"]),
        distinct: [json_extract_path(event.params, ["voter"]), json_extract_path(event.params, ["group"])],
        order_by: [asc: block.number],
        where: event.name == ^validator_group_vote_activated
      )

    activated_votes_for_group =
      query
      |> CeloContractEvent.query_by_voter_param(voter_address_hash)
      |> Repo.all()

    case activated_votes_for_group do
      [] ->
        {:error, :not_found}

      group ->
        {:ok,
         group
         |> Enum.map(&Common.ca/1)
         |> Enum.map(fn group_address_hash ->
           voter_rewards_for_group.calculate(voter_address_hash, group_address_hash)
         end)
         |> Enum.map(fn {:ok, %{group: group, rewards: rewards}} ->
           Enum.map(rewards, fn x -> Map.put(x, :group, group) end)
         end)
         |> List.flatten()
         |> Enum.filter(fn x ->
           DateTime.compare(x.date, from_date) != :lt && DateTime.compare(x.date, to_date) == :lt
         end)
         |> Enum.map_reduce(0, fn x, acc -> {x, acc + x.amount} end)
         |> then(fn {rewards, total} ->
           %{
             from: from_date,
             rewards: rewards,
             to: to_date,
             total_reward_celo: total,
             voter_account: voter_address_hash
           }
         end)}
    end
  end
end
