defmodule BlockScoutWeb.VerifiedContractsController do
  use BlockScoutWeb, :controller

  import Ecto.Query
  #alias Explorer.Chain

  def index(conn, _params) do
    contracts = get_verified_contracts()

    render(conn, "index.html", contracts: contracts)
  end

  def get_verified_contracts() do
    Explorer.Chain.SmartContract
    |> preload(:address)
    |> Explorer.Repo.all()
  end
end