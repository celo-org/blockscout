defmodule BlockScoutWeb.EpochTransactionView do
  use BlockScoutWeb, :view

  alias Explorer.Celo.Util
  alias Explorer.Celo.EpochUtil
  alias Explorer.Chain.Wei
  alias Explorer.Chain

  def get_reward_currency(reward_type) do
    case reward_type do
      "voter" -> "CELO"
      _ -> "cUSD"
    end
  end

  def get_reward_currency_address(reward_type) do
    with {:ok, address_string} <-
           Util.get_address(
             case reward_type do
               "voter" -> "GoldToken"
               _ -> "StableToken"
             end
           ),
         {:ok, address_hash} <- Chain.string_to_address_hash(address_string),
         {:ok, address} <- Chain.hash_to_address(address_hash) do
      address
    end
  end

  def wei_to_ether_rounded(amount), do: amount |> Wei.to(:ether) |> then(&Decimal.round(&1, 2))
end
