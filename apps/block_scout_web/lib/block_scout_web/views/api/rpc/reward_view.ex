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
      epochs: Enum.map(rewards.epochs, &prepare_epoch(&1))
    }
  end

  defp prepare_epoch(epoch) do
    %{amount: to_string(epoch.amount), date: epoch.date, epochNumber: to_string(epoch.epoch_number)}
  end
end
