defmodule BlockScoutWeb.VerifiedContractsController do
  use BlockScoutWeb, :controller

  #alias Explorer.Chain

  def index(conn, _params) do
    render(conn, "index.html")
  end
end