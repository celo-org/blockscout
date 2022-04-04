defmodule Explorer.Celo.CoreContractCacheTest do
  use Explorer.DataCase, async: false

  alias Explorer.Celo.CoreContracts

  describe "is_core_contract_address?" do
    test "correctly checks addresses" do
      test_address = "0xheycoolteststringwheredidyoufindit"
      test_contract_identifier = "TestID"

      start_supervised({CoreContracts, %{
        refresh_period: :timer.hours(1000),
        cache: %{test_contract_identifier => test_address}
      }})

      assert CoreContracts.is_core_contract_address?(test_address)

      test_address = "0xnewaddresshey"
      CoreContracts.update_cache(test_contract_identifier, test_address)

      assert CoreContracts.is_core_contract_address?(test_address)

      CoreContracts.refresh()

      assert CoreContracts.is_core_contract_address?(test_address)
    end
  end
end
