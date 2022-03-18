defmodule Explorer.Celo.ValidatorRewards do
  @moduledoc """
    Module responsible for calculating a validator's rewards for a given time frame.
  """
  import Explorer.Celo.Util,
    only: [
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

  def calculate(validator_address_hash, from_date, to_date) do
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
          amount: json_extract_path(event.params, ["validator_payment"]),
          date: block.timestamp,
          block_number: block.number,
          block_hash: block.hash,
          group: json_extract_path(event.params, ["group"])
        },
        order_by: [asc: block.number],
        where: event.topic == ^validator_epoch_payment_distributed,
        where: block.timestamp >= ^from_date,
        where: block.timestamp < ^to_date
      )

    activated_votes_for_group =
      query
      |> CeloContractEvent.query_by_validator_param(validator_address_hash)
      |> Repo.all()

    structured_activated_votes_for_group =
      activated_votes_for_group
      |> Enum.map(fn x ->
        Map.merge(x, %{group: Common.ca(x.group), epoch_number: epoch_by_block_number(x.block_number)})
      end)
      |> Enum.map_reduce(0, fn x, acc -> {x, acc + x.amount} end)
      |> then(fn {rewards, total} ->
        %{
          from: from_date,
          rewards: rewards,
          to: to_date,
          total_reward_celo: total,
          account: validator_address_hash
        }
      end)

    {:ok, structured_activated_votes_for_group}
  end
end
