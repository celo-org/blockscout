defmodule Explorer.Chain.CeloElectionRewardsTest do
  use Explorer.DataCase

  import Explorer.Factory

  alias Explorer.Chain
  alias Explorer.Chain.Wei

  alias Chain.{Address, Block, CeloElectionRewards}

  describe "get_rewards/2" do
    test "returns rewards for an account that has both voter and validator rewards" do
      %Address{hash: account_hash} = insert(:address)
      %Address{hash: group_hash} = insert(:address)
      insert(:celo_account, address: group_hash)
      %Block{number: block_number, timestamp: block_timestamp} = insert(:block, number: 17_280)

      insert(
        :celo_election_rewards,
        account_hash: account_hash,
        associated_account_hash: group_hash,
        block_number: block_number,
        block_timestamp: block_timestamp
      )

      insert(
        :celo_election_rewards,
        account_hash: account_hash,
        associated_account_hash: group_hash,
        block_number: block_number,
        block_timestamp: block_timestamp,
        reward_type: "validator"
      )

      {:ok, one_wei} = Wei.cast(1)

      assert CeloElectionRewards.get_rewards([account_hash], ["voter", "validator"], nil, nil) == [
               %{
                 account_hash: account_hash,
                 amount: one_wei,
                 associated_account_hash: group_hash,
                 block_number: block_number,
                 date: block_timestamp,
                 epoch_number: 1,
                 reward_type: "validator"
               },
               %{
                 account_hash: account_hash,
                 amount: one_wei,
                 associated_account_hash: group_hash,
                 block_number: block_number,
                 date: block_timestamp,
                 epoch_number: 1,
                 reward_type: "voter"
               }
             ]
    end

    test "returns rewards for a voter for given time frame" do
      %Address{hash: account_hash} = insert(:address)
      %Address{hash: group_hash} = insert(:address)
      insert(:celo_account, address: group_hash)

      %Block{number: block_1_number, timestamp: block_1_timestamp} =
        insert(:block, number: 17_280, timestamp: ~U[2021-04-20 16:00:00.000000Z])

      %Block{number: block_2_number, timestamp: block_2_timestamp} =
        insert(:block, number: 17_280 * 2, timestamp: ~U[2021-04-21 16:00:00.000000Z])

      %Block{number: block_3_number, timestamp: block_3_timestamp} =
        insert(:block, number: 17_280 * 4, timestamp: ~U[2021-04-23 16:00:00.000000Z])

      insert(
        :celo_election_rewards,
        account_hash: account_hash,
        associated_account_hash: group_hash,
        block_number: block_1_number,
        block_timestamp: block_1_timestamp
      )

      insert(
        :celo_election_rewards,
        account_hash: account_hash,
        associated_account_hash: group_hash,
        block_number: block_2_number,
        block_timestamp: block_2_timestamp
      )

      insert(
        :celo_election_rewards,
        account_hash: account_hash,
        associated_account_hash: group_hash,
        block_number: block_3_number,
        block_timestamp: block_3_timestamp
      )

      {:ok, one_wei} = Wei.cast(1)

      assert CeloElectionRewards.get_rewards(
               [account_hash],
               ["voter", "validator"],
               ~U[2021-04-21 00:00:00.000000Z],
               ~U[2021-04-22 00:00:00.000000Z]
             ) == [
               %{
                 account_hash: account_hash,
                 amount: one_wei,
                 associated_account_hash: group_hash,
                 block_number: block_2_number,
                 date: block_2_timestamp,
                 epoch_number: 2,
                 reward_type: "voter"
               }
             ]
    end
  end
end
