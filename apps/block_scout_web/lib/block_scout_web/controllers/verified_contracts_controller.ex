defmodule BlockScoutWeb.VerifiedContractsController do
  use BlockScoutWeb, :controller

  import Ecto.Query
  alias Explorer.Chain.SmartContract, as: Contract
  alias Explorer.GenericPagingOptions, as: PagingOptions

  @default_page_size 10

  def index(conn, params) do
    filter =
      if Map.has_key?(params, "filter") do
        Map.get(params, "filter")
      else
        nil
      end

    contract_count = get_verified_contract_count(filter)
    paging_options = extract_paging_options(params, contract_count, ["name"])
    contracts = get_verified_contracts(paging_options, filter)

    render(
      conn,
      "index.html",
      Keyword.merge(
        [contracts: contracts],
        prepare_paging_vars(
          conn,
          paging_options,
          params,
          contract_count,
          &path_for_paging_options/2
        )
      )
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
    |> order_by(asc: :name) # TODO parametrize (use fragment)
  end

  defp handle_filter(query, filter) do
    if not is_nil(filter)do
      # TODO implement WHERE clause
      query
    else
      query
    end
  end

  defp path_for_paging_options(conn, paging_options) do
    verified_contracts_path(conn, :index, paging_options)
  end

  # TODO below functions should be moved to a helper

  # TODO validate paging options
  # TODO add error handling
  defp extract_paging_options(
    params,
    total_item_count,
    allowed_order_fields
  ) do
    page_size = if Map.has_key?(params, "page_size") do
      case Integer.parse(Map.get(params, "page_size", @default_page_size)) do
        {page_size, _} -> page_size
        :error -> @default_page_size
      end
    else
      @default_page_size
    end
    page_number = if Map.has_key?(params, "page_number") do
      page_number = case Integer.parse(Map.get(params, "page_number", 1)) do
        {page_number, _} -> page_number
        :error -> 1
      end

      if page_number > ceil(total_item_count / page_size) do
        1
      else
        page_number
      end
    else
      1
    end
    order_field = if Enum.count(allowed_order_fields) > 0 do
      if Map.has_key?(params, "order_field") and Enum.member?(allowed_order_fields, Map.get(params, "order_field")) do
        Map.get(params, "order_field")
      else
        Enum.at(allowed_order_fields, 0)
      end
    else
      nil
    end
    order_dir = if Map.has_key?(params, "order_dir") and Enum.member?(["desc", "asc"], Map.get(params, "order_dir")) do
      Map.get(params, "order_dir")
    else
      "asc"
    end

    %PagingOptions{
      order_field: order_field,
      order_dir: order_dir,
      page_size: page_size,
      page_number: page_number,
    }
  end

  defp prepare_paging_vars(
    conn,
    paging_options,
    params,
    total_item_count,
    path_fun
  ) do
    last_page_number = ceil(total_item_count / paging_options.page_size)

    [
      pagination_next_page_path: if paging_options.page_number * paging_options.page_size >= total_item_count do
        nil
      else
        path_fun.(conn, Map.merge(params, Map.from_struct(%{paging_options | page_number: paging_options.page_number + 1})))
      end,
      pagination_prev_page_path: if paging_options.page_number == 1 do
        nil
      else
        path_fun.(conn, Map.merge(params, Map.from_struct(%{paging_options | page_number: paging_options.page_number - 1})))
      end,
      pagination_first_page_path: if paging_options.page_number == 1 do
        nil
      else
        path_fun.(conn, Map.merge(params, Map.from_struct(%{paging_options | page_number: 1})))
      end,
      pagination_last_page_path: if paging_options.page_number == last_page_number do
        nil
      else
        path_fun.(conn, Map.merge(params, Map.from_struct(%{paging_options | page_number: last_page_number})))
      end,
      pagination_current_page: paging_options.page_number
    ]
  end
end
