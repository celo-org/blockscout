defmodule BlockScoutWeb.API.RPC.EpochView do
  use BlockScoutWeb, :view

  alias BlockScoutWeb.API.RPC.RPCView

  alias Explorer.Chain.Wei

  def render(json, %{rewards: rewards})
      when json in ~w(getvoterrewards.json getvalidatorrewards.json getgrouprewards.json) do
    RPCView.render("show.json", data: prepare_response(json, rewards))
  end

  def render("error.json", assigns) do
    RPCView.render("error.json", assigns)
  end

  def prepare_response("getvoterrewards.json", rewards),
    do: rewards |> wrap_rewards([{"groupAddress", :associated_account_hash}], :celo)

  def prepare_response("getvalidatorrewards.json", rewards),
    do: rewards |> wrap_rewards([{"groupAddress", :associated_account_hash}], :cusd)

  def prepare_response("getgrouprewards.json", rewards),
    do: rewards |> wrap_rewards([{"validatorAddress", :associated_account_hash}], :cusd)

  def wrap_rewards(rewards, meta, currency) do
    %{
      totalRewardAmounts: rewards.total_amount |> prepare_amounts(currency),
      totalRewardCount: to_string(rewards.total_count),
      from: to_string(rewards.from),
      to: to_string(rewards.to),
      rewards: Enum.map(rewards.rewards, fn reward -> prepare_rewards_response_item(reward, meta, currency) end)
    }
  end

  defp prepare_rewards_response_item(reward, meta, currency) do
    {:ok, reward_address_locked_gold_wei} = Wei.cast(reward.account_locked_gold)
    {:ok, reward_address_activated_gold_wei} = Wei.cast(reward.account_activated_gold)

    %{
      amounts: reward.amount |> prepare_amounts(currency),
      blockHash: to_string(reward.block_hash),
      blockNumber: to_string(reward.block_number),
      blockTimestamp: reward.date |> DateTime.to_iso8601(),
      epochNumber: to_string(reward.epoch_number),
      meta:
        Map.new(Enum.map(meta, fn {meta_key, reward_key} -> {meta_key, to_string(Map.get(reward, reward_key))} end)),
      rewardAddress: to_string(reward.account_hash),
      rewardAddressActivatedGold: reward_address_activated_gold_wei |> to_celo_wei_amount,
      rewardAddressLockedGold: reward_address_locked_gold_wei |> to_celo_wei_amount
    }
  end

  defp prepare_amounts(amount, :celo), do: amount |> to_celo_wei_amount
  defp prepare_amounts(amount, :cusd), do: amount |> to_currency_amount("cUSD")

  defp to_celo_wei_amount(wei),
    do: %{
      celo: to_string(wei |> Wei.to(:ether)),
      wei: to_string(wei)
    }

  defp to_currency_amount(amount, currency_symbol),
    do: %{
      currency_symbol => to_string(amount |> Wei.to(:ether))
    }
end
