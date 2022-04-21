defmodule BlockScoutWeb.VerifiedContractsController do
  use BlockScoutWeb, :controller

  import Ecto.Query
  alias Explorer.Chain.SmartContract, as: Contract
  alias BlockScoutWeb.GenericPagingOptions, as: PagingOptions
  alias BlockScoutWeb.VerifiedContractsView

  @default_page_size 10

  def index(conn, params) do
    filter = Map.get(params, "filter")
    contract_count = get_verified_contract_count(filter)

    paging_options =
      PagingOptions.extract_paging_options_from_params(
        params,
        contract_count,
        ["name"],
        @default_page_size
      )

    contracts = get_verified_contracts(paging_options, filter)

    render(conn, VerifiedContractsView, "index.html",
      conn: conn,
      params: params,
      contracts: contracts,
      contract_count: contract_count,
      paging_options: paging_options
    )
  end

  defp get_verified_contracts(paging_options, filter) do
    Contract
    |> preload(:address)
    |> handle_filter(filter)
    |> handle_paging_options(paging_options)
    |> Explorer.Repo.all()
  end

  defp get_verified_contract_count(filter) do
    Contract
    |> handle_filter(filter)
    |> Explorer.Repo.aggregate(:count, :id)
  end

  defp handle_paging_options(query, paging_options) do
    offset = (paging_options.page_number - 1) * paging_options.page_size

    query
    |> limit(^paging_options.page_size)
    |> offset(^offset)
    # TODO parametrize (use fragment)
    |> order_by(asc: :name)
  end

  defp handle_filter(query, filter) do
    if not is_nil(filter) do
      # TODO implement WHERE clause
      query
    else
      query
    end
  end

  # defp path_for_paging_options
end
