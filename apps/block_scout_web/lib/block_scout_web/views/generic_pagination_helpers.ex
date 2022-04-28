defmodule BlockScoutWeb.GenericPaginationHelpers do
  @moduledoc """
  Helpers for handling pagination
  """

  @spec next_page_path(
          conn :: any(),
          params :: map(),
          paging_options :: BlockScoutWeb.GenericPagingOptions.generic_paging_options(),
          total_item_count :: pos_integer(),
          path_fun :: any()
        ) :: String.t() | nil
  def next_page_path(conn, params, paging_options, total_item_count, path_fun) do
    if paging_options.page_number * paging_options.page_size >= total_item_count do
      nil
    else
      path_fun.(conn, Map.merge(params, %{paging_options | page_number: paging_options.page_number + 1}))
    end
  end

  @spec prev_page_path(
          conn :: any(),
          params :: map(),
          paging_options :: BlockScoutWeb.GenericPagingOptions.generic_paging_options(),
          path_fun :: any()
        ) :: String.t() | nil
  def prev_page_path(conn, params, paging_options, path_fun) do
    if paging_options.page_number == 1 do
      nil
    else
      path_fun.(conn, Map.merge(params, %{paging_options | page_number: paging_options.page_number - 1}))
    end
  end

  @spec first_page_path(
          conn :: any(),
          params :: map(),
          paging_options :: BlockScoutWeb.GenericPagingOptions.generic_paging_options(),
          path_fun :: any()
        ) :: String.t() | nil
  def first_page_path(conn, params, paging_options, path_fun) do
    if paging_options.page_number == 1 do
      nil
    else
      path_fun.(conn, Map.merge(params, %{paging_options | page_number: 1}))
    end
  end

  @spec last_page_path(
          conn :: any(),
          params :: map(),
          paging_options :: BlockScoutWeb.GenericPagingOptions.generic_paging_options(),
          total_item_count :: pos_integer(),
          path_fun :: any()
        ) :: String.t() | nil
  def last_page_path(conn, params, paging_options, total_item_count, path_fun) do
    last_page_number = ceil(total_item_count / paging_options.page_size)

    if paging_options.page_number == last_page_number do
      nil
    else
      path_fun.(conn, Map.merge(params, %{paging_options | page_number: last_page_number}))
    end
  end

  @spec current_page(paging_options :: BlockScoutWeb.GenericPagingOptions.generic_paging_options()) :: pos_integer()
  def current_page(paging_options), do: paging_options.page_number

  def sort_path(conn, params, paging_options, field, default_order_dir, path_fun) do
    path_fun_params =
      params
      |> Map.merge(paging_options)
      |> Map.merge(
        if paging_options.order_field == field do
          if paging_options.order_dir == "desc", do: %{order_dir: "asc"}, else: %{order_dir: "desc"}
        else
          %{order_field: field, order_dir: default_order_dir}
        end
      )

    path_fun.(conn, path_fun_params)
  end
end
