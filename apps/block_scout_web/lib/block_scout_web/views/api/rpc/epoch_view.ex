defmodule BlockScoutWeb.API.RPC.EpochView do
  use BlockScoutWeb, :view

  alias BlockScoutWeb.API.RPC.RPCView

  alias Explorer.Chain.Wei

  def render(json, %{rewards: rewards}) when json in ~w(getvoterrewards.json) do
    prepared_rewards = prepare_voter_rewards(rewards)

    RPCView.render("show.json", data: prepared_rewards)
  end

  def render("error.json", assigns) do
    RPCView.render("error.json", assigns)
  end

  defp prepare_voter_rewards(rewards) do
    %{
      totalAmount: rewards.total_amount |> to_celo_wei_amount,
      totalCount: to_string(rewards.total_count),
      from: to_string(rewards.from),
      to: to_string(rewards.to),
      rewards: Enum.map(rewards.rewards, &prepare_voter_reward(&1))
    }
  end

  defp prepare_voter_reward(reward) do
    {:ok, voter_locked_gold_wei} = Wei.cast(reward.voter_locked_gold)
    {:ok, voter_activated_gold_wei} = Wei.cast(reward.voter_activated_gold)

    %{
      blockHash: to_string(reward.block_hash),
      blockNumber: to_string(reward.block_number),
      epochNumber: to_string(reward.epoch_number),
      voterAddress: to_string(reward.voter_address_hash),
      voterLockedGold: voter_locked_gold_wei |> to_celo_wei_amount,
      voterActivatedGold: voter_activated_gold_wei |> to_celo_wei_amount,
      groupAddress: to_string(reward.group_address_hash),
      date: reward.date |> DateTime.to_iso8601(),
      amount: reward.amount |> to_celo_wei_amount
    }
  end

  defp to_celo_wei_amount(wei),
    do: %{
      celo: to_string(wei |> Wei.to(:ether)),
      wei: to_string(wei)
    }
end
