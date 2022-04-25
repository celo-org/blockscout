defmodule BlockScoutWeb.GenericPagingOptions do
  @moduledoc """
  Defines generic paging options for paging by any key.
  """

  @type generic_paging_options :: {
          order_field :: String.t() | nil,
          order_dir :: String.t() | nil,
          page_size :: non_neg_integer(),
          page_number :: pos_integer()
        }

  @spec extract_paging_options_from_params(
          params :: map(),
          total_item_count :: non_neg_integer(),
          allowed_order_fields :: list(String.t()),
          default_order_dir :: String.t(),
          default_page_size :: pos_integer()
        ) :: generic_paging_options
  def extract_paging_options_from_params(
        params,
        total_item_count,
        allowed_order_fields,
        default_order_dir,
        default_page_size
      ) do
    page_size =
      if Map.has_key?(params, "page_size") do
        case Integer.parse(Map.get(params, "page_size", default_page_size)) do
          {page_size, _} -> page_size
          :error -> default_page_size
        end
      else
        default_page_size
      end

    page_number =
      if Map.has_key?(params, "page_number") do
        page_number =
          case Integer.parse(Map.get(params, "page_number", 1)) do
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

    order_field =
      if Enum.count(allowed_order_fields) > 0 do
        if Map.has_key?(params, "order_field") and Enum.member?(allowed_order_fields, Map.get(params, "order_field")) do
          Map.get(params, "order_field")
        else
          Enum.at(allowed_order_fields, 0)
        end
      else
        nil
      end

    order_dir =
      if Map.has_key?(params, "order_dir") and Enum.member?(["desc", "asc"], Map.get(params, "order_dir")) do
        Map.get(params, "order_dir")
      else
        default_order_dir
      end

    %{
      order_field: order_field,
      order_dir: order_dir,
      page_size: page_size,
      page_number: page_number
    }
  end
end
