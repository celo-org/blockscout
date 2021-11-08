defmodule Explorer.Celo.CacheHelper do
  def set_test_address(address \\ "0x000000000000000000000000000000000000ce10") do
    Explorer.Celo.AddressCache.Mock |> Mox.stub(:contract_address, fn _name -> address end)
  end
  def empty_address_cache() do
    Explorer.Celo.AddressCache.Mock |> Mox.stub(:contract_address, fn _name -> :error end)
  end
end