defmodule BlockScoutWeb.API.RPC.RewardView do
  use BlockScoutWeb, :view

  alias BlockScoutWeb.API.RPC.RPCView

  def render("getvoterrewardsforgroup.json", %{rewards: rewards}) do
    prepared_rewards = prepare_rewards(rewards)

    RPCView.render("show.json", data: prepared_rewards)
  end

  def render("error.json", assigns) do
    RPCView.render("error.json", assigns)
  end

  defp prepare_rewards(rewards) do
    %{
      total: to_string(rewards.total),
      rewards: Enum.map(rewards.rewards, &prepare_reward(&1))
    }
  end

  defp prepare_reward(reward) do
    %{
      amount: to_string(reward.amount),
      block_hash: to_string(reward.block_hash),
      block_number: to_string(reward.block_number),
      date: reward.date,
      epochNumber: to_string(reward.epoch_number)
     }
  end
end
