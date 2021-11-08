defmodule Explorer.Celo.AddressCache do
  @doc """
  Fetch a contract address for a given name
  """
  @callback contract_address(String.t) :: String.t

  @implementation Application.fetch_env!(:explorer, __MODULE__)

  defdelegate contract_address(contract_name), to: @implementation
end