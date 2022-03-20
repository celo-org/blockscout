defmodule Explorer.Celo.ValidatorGroupRewards do
  @moduledoc """
    Module responsible for calculating a validator's rewards for a given time frame.
  """
  import Explorer.Celo.Util,
    only: [
      add_input_account_to_individual_rewards_and_calculate_sum: 2,
      epoch_by_block_number: 1
    ]

  import Ecto.Query,
    only: [
      from: 2
    ]

  alias Explorer.Chain.{Block, CeloContractEvent}
  alias Explorer.Repo

  alias Explorer.Celo.ContractEvents.{Common, Validators}

  alias Validators.ValidatorEpochPaymentDistributedEvent

  def calculate(group_address_hash, from_date, to_date) do
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

    validator_epoch_payment_distributed = ValidatorEpochPaymentDistributedEvent.topic()

    query =
      from(event in CeloContractEvent,
        inner_join: block in Block,
        on: event.block_number == block.number,
        select: %{
          amount: json_extract_path(event.params, ["group_payment"]),
          date: block.timestamp,
          block_number: block.number,
          block_hash: block.hash,
          validator: json_extract_path(event.params, ["validator"])
        },
        order_by: [asc: block.number],
        where: event.topic == ^validator_epoch_payment_distributed,
        where: block.timestamp >= ^from_date,
        where: block.timestamp < ^to_date
      )

    activated_votes_for_group =
      query
      |> CeloContractEvent.query_by_group_param(group_address_hash)
      |> Repo.all()

    structured_activated_votes_for_group =
      activated_votes_for_group
      |> Enum.map(fn x ->
        Map.merge(x, %{validator: Common.ca(x.validator), epoch_number: epoch_by_block_number(x.block_number)})
      end)
      |> Enum.map_reduce(0, fn x, acc -> {x, acc + x.amount} end)
      |> then(fn {rewards, total} ->
        %{
          from: from_date,
          rewards: rewards,
          to: to_date,
          total_reward_celo: total,
          group: group_address_hash
        }
      end)

    {:ok, structured_activated_votes_for_group}
  end

  def calculate_multiple_accounts(voter_address_hash_list, from_date, to_date) do
    reward_lists_chunked_by_account =
      voter_address_hash_list
      |> Enum.map(fn hash -> calculate(hash, from_date, to_date) end)

    {rewards, rewards_sum} =
      add_input_account_to_individual_rewards_and_calculate_sum(reward_lists_chunked_by_account, :group)

    {:ok, %{from: from_date, to: to_date, rewards: rewards, total_reward_celo: rewards_sum}}
  end
end
