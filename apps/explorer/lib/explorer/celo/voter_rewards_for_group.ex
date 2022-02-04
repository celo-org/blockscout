defmodule Explorer.Celo.VoterRewardsForGroup do
  @moduledoc """
    Module responsible for calculating a voter's rewards for a specific group. Extracted for testing purposes.
  """

  import Ecto.Query,
         only: [
           from: 2
         ]

  alias ABI.TypeDecoder
  alias Explorer.Celo.{Events, Util}
  alias Explorer.Chain.{Block, CeloValidatorGroupVotes, Log, Wei}
  alias Explorer.Repo

  def calculate(voter_address_hash, group_address_hash) do
    [validator_group_active_vote_revoked, _, validator_group_vote_activated, _] = Events.voter_events()
    [epoch_rewards_distributed_to_voters] = Events.distributed_events()

    query =
      from(log in Log,
        select: %{
          block_hash: log.block_hash,
          block_number: log.block_number,
          amount_activated_or_revoked: log.data,
          event: log.first_topic,
          voter_hash: log.second_topic,
          group_hash: log.third_topic
        },
        order_by: [asc: log.block_number],
        where:
          log.first_topic == ^validator_group_active_vote_revoked or
          log.first_topic == ^validator_group_vote_activated,
        where: log.second_topic == ^voter_address_hash,
        where: log.third_topic == ^group_address_hash
      )

    query
    |> Repo.all()
    |> Enum.map(fn x ->
      %Explorer.Chain.Data{bytes: amount_activated_or_revoked_bytes} = x.amount_activated_or_revoked

      [amount_activated_or_revoked_int | _] =
        TypeDecoder.decode_raw(amount_activated_or_revoked_bytes, [{:uint, 256}, {:uint, 256}])

      Map.put(x, :amount_activated_or_revoked, amount_activated_or_revoked_int)
    end)
    |> case do
         [] ->
           {:error, :not_found}

         voter_activated_or_revoked ->
           [voter_activated_earliest_block | _] = voter_activated_or_revoked

           query =
             from(log in Log,
               inner_join: votes in CeloValidatorGroupVotes,
               on: log.block_hash == votes.block_hash,
               inner_join: block in Block,
               on: log.block_hash == block.hash,
               select: %{
                 block_hash: log.block_hash,
                 block_number: log.block_number,
                 date: block.timestamp,
                 epoch_reward: log.data,
                 event: log.first_topic,
                 group_hash: log.second_topic,
                 previous_block_group_votes: votes.previous_block_active_votes
               },
               where:
                 log.block_number >= ^voter_activated_earliest_block.block_number and
                 log.first_topic == ^epoch_rewards_distributed_to_voters and
                 log.second_topic == ^group_address_hash
             )

           {epochs, total} =
             query
             |> Repo.all()
             |> Enum.map_reduce(voter_activated_earliest_block.amount_activated_or_revoked, fn curr, amount ->
               amount_activated_or_revoked =
                 amount_activated_or_revoked_last_day(voter_activated_or_revoked, curr.block_number)

               amount =
                 amount_after_activated_or_revoked(amount_activated_or_revoked, amount, voter_activated_earliest_block)

               %Explorer.Chain.Data{bytes: epoch_reward_bytes} = curr.epoch_reward
               [epoch_reward] = TypeDecoder.decode_raw(epoch_reward_bytes, [{:uint, 256}])

               {:ok, previous_block_group_votes_decimal} = Wei.dump(curr.previous_block_group_votes)

               current_amount = div(epoch_reward * amount, Decimal.to_integer(previous_block_group_votes_decimal))

               {%{amount: current_amount, date: curr.date, epoch_number: Util.epoch_by_block_number(curr.block_number)},
                 amount + current_amount}
             end)

           {:ok, %{epochs: epochs, total: total}}
       end
  end

  def amount_activated_or_revoked_last_day(voter_activated_or_revoked, block_number) do
    [_, _, validator_group_vote_activated, _] = Events.voter_events()

    voter_activated_or_revoked
    |> Enum.filter(&(&1.block_number < block_number && &1.block_number >= block_number - 17280))
    |> Enum.reduce(0, fn x, acc ->
      if x.event == validator_group_vote_activated do
        acc + x.amount_activated_or_revoked
      else
        acc - x.amount_activated_or_revoked
      end
    end)
  end

  def amount_after_activated_or_revoked(amount_activated_or_revoked, amount, voter_activated_earliest_block) do
    if voter_activated_earliest_block.amount_activated_or_revoked != amount &&
         amount_activated_or_revoked != 0 do
      amount + amount_activated_or_revoked
    else
      amount
    end
  end
end
