defmodule Explorer.Export.CSV.Exporter do
  alias Explorer.Chain.Address

  @callback row_names() :: [String.t()]
  @callback associations() :: list(term())
  @callback transform(object :: term(), address :: Address.t()) :: term()
  @callback query(address :: Address.t(), from_period :: String.t(), to_period :: String.t()) :: Ecto.Query.t()
end