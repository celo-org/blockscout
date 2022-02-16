defmodule Explorer.Celo.VoterRewardsForGroup do
  @moduledoc """
    Module responsible for calculating a voter's rewards for a specific group. Extracted for testing purposes.
  """

  import Ecto.Query,
    only: [
      from: 2
    ]

  alias Explorer.Celo.{ContractEvents, Events, Util}
  alias Explorer.Chain.{Block, CeloContractEvent, CeloValidatorGroupVotes, Wei}
  alias Explorer.Repo

  alias ContractEvents.Election

  alias Election.{
    EpochRewardsDistributedToVotersEvent,
    ValidatorGroupActiveVoteRevokedEvent,
    ValidatorGroupVoteActivatedEvent
  }

  @validator_group_vote_activated ValidatorGroupVoteActivatedEvent.name()

  def calculate(voter_address_hash, group_address_hash) do
    validator_group_active_vote_revoked = ValidatorGroupActiveVoteRevokedEvent.name()
    epoch_rewards_distributed_to_voters = EpochRewardsDistributedToVotersEvent.name()

    query =
      from(event in CeloContractEvent,
        inner_join: block in Block,
        on: event.block_hash == block.hash,
        select: %{
          block_hash: event.block_hash,
          block_number: block.number,
          amount_activated_or_revoked: json_extract_path(event.params, ["value"]),
          event: event.name
        },
        order_by: [asc: block.number],
        where:
          event.name == ^validator_group_active_vote_revoked or
            event.name == ^@validator_group_vote_activated
      )

    query
    |> CeloContractEvent.query_by_voter_param(voter_address_hash)
    |> CeloContractEvent.query_by_group_param(group_address_hash)
    |> Repo.all()
    |> case do
      [] ->
        {:error, :not_found}

      voter_activated_or_revoked ->
        [voter_activated_earliest_block | _] = voter_activated_or_revoked

        query =
          from(event in CeloContractEvent,
            inner_join: votes in CeloValidatorGroupVotes,
            on: event.block_hash == votes.block_hash,
            inner_join: block in Block,
            on: event.block_hash == block.hash,
            select: %{
              block_hash: event.block_hash,
              block_number: block.number,
              date: block.timestamp,
              epoch_reward: json_extract_path(event.params, ["value"]),
              event: event.name,
              previous_block_group_votes: votes.previous_block_active_votes
            },
            where:
              event.block_hash >= ^voter_activated_earliest_block.block_hash and
                event.name == ^epoch_rewards_distributed_to_voters
          )

        {rewards, total} =
          query
          |> CeloContractEvent.query_by_group_param(group_address_hash)
          |> Repo.all()
          |> Enum.map_reduce(0, fn curr, amount ->
            amount_activated_or_revoked =
              amount_activated_or_revoked_last_day(voter_activated_or_revoked, curr.block_number)

            amount = amount + amount_activated_or_revoked

            epoch_reward = curr.epoch_reward

            {:ok, previous_block_group_votes_decimal} = Wei.dump(curr.previous_block_group_votes)

            current_amount = div(epoch_reward * amount, Decimal.to_integer(previous_block_group_votes_decimal))

            {
              %{
                amount: current_amount,
                block_hash: curr.block_hash,
                block_number: curr.block_number,
                date: curr.date,
                epoch_number: Util.epoch_by_block_number(curr.block_number)
              },
              amount + current_amount
            }
          end)

        {:ok, %{rewards: rewards, total: total, group: group_address_hash}}
    end
  end

  def amount_activated_or_revoked_last_day(voter_activated_or_revoked, block_number) do

    voter_activated_or_revoked
    |> Enum.filter(&(&1.block_number < block_number && &1.block_number >= block_number - 17280))
    |> Enum.reduce(0, fn x, acc ->
      if x.event == @validator_group_vote_activated do
        acc + x.amount_activated_or_revoked
      else
        acc - x.amount_activated_or_revoked
      end
    end)
  end
end
