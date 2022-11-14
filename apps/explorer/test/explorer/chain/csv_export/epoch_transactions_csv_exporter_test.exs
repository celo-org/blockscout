defmodule Explorer.CSV.Export.EpochTransactionsCsvExporterTest do
  use Explorer.DataCase

  alias Explorer.Chain.{Address, Block, AddressTokenTransferCsvExporter}

  describe "export/3" do
    test "exports epoch transactions to csv" do
      address = insert(:address)
      epoch_number = 902
      %Address{hash: from_address_hash} = insert(:address)

      block =
        insert(
          :block,
          number: 17_280 * epoch_number,
          timestamp: ~U[2022-10-12T18:53:12.162804Z]
        )

      reward =
        insert(
          :celo_election_rewards,
          account_hash: address.hash,
          associated_account_hash: from_address_hash,
          block_number: block.number,
          block_timestamp: block.timestamp,
          block_hash: block.hash,
          amount: 123_456_789_012_345_678_901,
          reward_type: "voter"
        )

      {:ok, csv} = Explorer.Export.CSV.export_epoch_transactions(address, [])

      [result] =
        csv
        |> Enum.drop(1)
        |> Enum.map(fn [
                         epoch_number,
                         _,
                         block_number,
                         _,
                         timestamp,
                         _,
                         from_address,
                         _,
                         reward_type,
                         _,
                         value,
                         _
                       ] ->
          %{
            epoch_number: epoch_number,
            block_number: block_number,
            timestamp: timestamp,
            from_address: from_address,
            reward_type: reward_type,
            value: value
          }
        end)

      assert result.epoch_number == to_string(epoch_number)
      assert result.block_number == to_string(block.number)
      assert result.from_address == from_address_hash |> to_string() |> String.downcase()
      assert result.timestamp == to_string(reward.block_timestamp)
      assert result.reward_type == reward.reward_type
      assert result.value == to_string(reward.amount)
    end
  end
end
