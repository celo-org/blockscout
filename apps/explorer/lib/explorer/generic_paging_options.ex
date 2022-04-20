defmodule Explorer.GenericPagingOptions do
  @moduledoc """
  Defines generic paging options for paging by any key.
  """

  @type t :: %__MODULE__{
          order_field: order_field,
          order_dir: order_dir,
          page_size: page_size,
          page_number: page_number
        }

  @typep order_field :: String.t() | nil
  @typep order_dir :: String.t() | nil
  @typep page_size :: non_neg_integer()
  @typep page_number :: pos_integer()

  defstruct [order_field: nil, order_dir: nil, page_size: 10, page_number: 1]
end
