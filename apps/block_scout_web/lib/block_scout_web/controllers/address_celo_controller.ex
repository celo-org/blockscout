defmodule BlockScoutWeb.AddressCeloController do
  use BlockScoutWeb, :controller

  require Logger

  alias Explorer.{Chain, Market}
  alias Explorer.ExchangeRates.Token
  alias Indexer.Fetcher.CoinBalanceOnDemand

  alias Explorer.Chain.CeloAccount

  def index(conn, %{"address_id" => address_hash_string}) do
    with {:ok, address_hash} <- Chain.string_to_address_hash(address_hash_string),
         {:ok, address} <- Chain.hash_to_address(address_hash),
         %CeloAccount{address: _} <- address.celo_account do
      Logger.debug("Parsing Celo Address #{address_hash_string}")

      render(
        conn,
        "index.html",
        address: address,
        current_path: current_path(conn),
        coin_balance_status: CoinBalanceOnDemand.trigger_fetch(address),
        exchange_rate: Market.get_exchange_rate("CELO") || Market.get_exchange_rate("cGLD") || Token.null(),
        counters_path: address_path(conn, :address_counters, %{"id" => address_hash_string})
      )
    else
      _ ->
        not_found(conn)
    end
  end
end
