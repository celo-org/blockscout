defmodule Explorer.Celo.RebuildAttestationStatsTest do
  use Explorer.DataCase

  describe "rebuild_attestation_stats/1" do
    setup do
     #insert celo account
     [account: insert(:celo_account)]
    end

    test "updates attestation stats for a given account", %{account: account} do

      IO.inspect(account)
      # assert account attestations
      # insert logs corresponding to attestation requested
      # assert value (may have to change)
      # run query
      # assert updated value
    end
  end
end

