defmodule BlockScoutWeb.GenericPaginationHelpers do
  @moduledoc """
  Helpers for handling pagination
  """

  @spec next_page_path(
          conn :: any(),
          params :: map(),
          paging_options :: map(),
          total_item_count :: pos_integer(),
          path_fun :: any()
        ) :: String.t()
  def next_page_path(conn, params, paging_options, total_item_count, path_fun) do
    if paging_options.page_number * paging_options.page_size >= total_item_count do
      nil
    else
      path_fun.(conn, Map.merge(params, %{paging_options | page_number: paging_options.page_number + 1}))
    end
  end

  @spec prev_page_path(conn :: any(), params :: map(), paging_options :: map(), path_fun :: any()) :: String.t()
  def prev_page_path(conn, params, paging_options, path_fun) do
    if paging_options.page_number == 1 do
      nil
    else
      path_fun.(conn, Map.merge(params, %{paging_options | page_number: paging_options.page_number - 1}))
    end
  end

  @spec first_page_path(conn :: any(), params :: map(), paging_options :: map(), path_fun :: any()) :: String.t()
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
          paging_options :: map(),
          total_item_count :: pos_integer(),
          path_fun :: any()
        ) :: String.t()
  def last_page_path(conn, params, paging_options, total_item_count, path_fun) do
    last_page_number = ceil(total_item_count / paging_options.page_size)

    if paging_options.page_number == last_page_number do
      nil
    else
      path_fun.(conn, Map.merge(params, %{paging_options | page_number: last_page_number}))
    end
  end

  def current_page(paging_options), do: paging_options.page_number
end
