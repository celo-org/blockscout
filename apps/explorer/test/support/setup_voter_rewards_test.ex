alias Explorer.Celo.Events
alias Explorer.Chain
alias Explorer.Chain.Address

import Explorer.Factory

defmodule Explorer.SetupVoterRewardsTest do
  def setup do
    [validator_group_active_vote_revoked, _, validator_group_vote_activated, _] = Events.voter_events()
    [epoch_rewards_distributed_to_voters] = Events.distributed_events()
    %Address{hash: voter_address_1_hash} = voter_address_1 = insert(:address)
    %Address{hash: voter_address_2_hash} = voter_address_2 = insert(:address)
    %Address{hash: group_address_hash} = group_address = insert(:address)
    election_proxy_address = insert(:address)

    block_1 = insert(:block, number: 10_692_863, timestamp: ~U[2022-01-01 13:08:43.162804Z])

    transaction_1 =
      :transaction
      |> insert(from_address: voter_address_1)
      |> with_block(block_1)

    # voter_1 activates votes for group_1 on January 1st and is the only voter
    insert(:log,
      address: voter_address_1,
      block: transaction_1.block,
      block_number: transaction_1.block_number,
      data: Chain.raw_abi_encode_integers([650, 10000]),
      first_topic: validator_group_vote_activated,
      second_topic: to_string(voter_address_1_hash),
      third_topic: to_string(group_address_hash),
      index: 1,
      transaction: transaction_1
    )

    block_2 = insert(:block, number: 10_727_421, timestamp: ~U[2022-01-03 13:08:43.162804Z])

    transaction_2 =
      :transaction
      |> insert(from_address: voter_address_1)
      |> with_block(block_2)

    # voter_2 activates votes for group_1 on January 3rd
    insert(:log,
      address: voter_address_2,
      block: transaction_2.block,
      block_number: transaction_2.block_number,
      data: Chain.raw_abi_encode_integers([250, 10000]),
      first_topic: validator_group_vote_activated,
      second_topic: to_string(voter_address_2_hash),
      third_topic: to_string(group_address_hash),
      index: 2,
      transaction: transaction_2
    )

    block_3 = insert(:block, number: 10_744_696, timestamp: ~U[2022-01-04 13:08:43.162804Z])

    transaction_3 =
      :transaction
      |> insert(from_address: voter_address_1)
      |> with_block(block_3)

    # voter_1 revokes votes for group_1 on January 4th
    insert(:log,
      address: voter_address_1,
      block: transaction_3.block,
      block_number: transaction_3.block_number,
      data: Chain.raw_abi_encode_integers([650, 10000]),
      first_topic: validator_group_active_vote_revoked,
      second_topic: to_string(voter_address_1_hash),
      third_topic: to_string(group_address_hash),
      index: 2,
      transaction: transaction_3
    )

    block_4 = insert(:block, number: 10_761_966, timestamp: ~U[2022-01-05 13:08:43.162804Z])

    transaction_4 =
      :transaction
      |> insert(from_address: voter_address_1)
      |> with_block(block_4)

    # voter_2 revokes votes for group_1 on January 5th
    insert(:log,
      address: voter_address_1,
      block: transaction_4.block,
      block_number: transaction_4.block_number,
      data: Chain.raw_abi_encode_integers([324, 10000]),
      first_topic: validator_group_active_vote_revoked,
      second_topic: to_string(voter_address_2_hash),
      third_topic: to_string(group_address_hash),
      index: 2,
      transaction: transaction_4
    )

    block_5 = insert(:block, number: 10_796_524, timestamp: ~U[2022-01-07 13:08:43.162804Z])

    transaction_5 =
      :transaction
      |> insert(from_address: voter_address_1)
      |> with_block(block_5)

    # voter_1 revokes votes for group_1 on January 7th
    insert(:log,
      address: voter_address_1,
      block: transaction_5.block,
      block_number: transaction_5.block_number,
      data: Chain.raw_abi_encode_integers([350, 10000]),
      first_topic: validator_group_active_vote_revoked,
      second_topic: to_string(voter_address_1_hash),
      third_topic: to_string(group_address_hash),
      index: 2,
      transaction: transaction_5
    )

    block_6 = insert(:block, number: 10_696_320, timestamp: ~U[2022-01-01 17:42:43.162804Z])

    transaction_6 =
      :transaction
      |> insert(from_address: election_proxy_address)
      |> with_block(block_6)

    block_7 = insert(:block, number: 10_713_600, timestamp: ~U[2022-01-02 17:42:43.162804Z])

    transaction_7 =
      :transaction
      |> insert(from_address: election_proxy_address)
      |> with_block(block_7)

    block_8 = insert(:block, number: 10_730_880, timestamp: ~U[2022-01-03 17:42:43.162804Z])

    transaction_8 =
      :transaction
      |> insert(from_address: election_proxy_address)
      |> with_block(block_8)

    block_9 = insert(:block, number: 10_748_160, timestamp: ~U[2022-01-04 17:42:43.162804Z])

    transaction_9 =
      :transaction
      |> insert(from_address: election_proxy_address)
      |> with_block(block_9)

    block_10 = insert(:block, number: 10_765_440, timestamp: ~U[2022-01-05 17:42:43.162804Z])

    transaction_10 =
      :transaction
      |> insert(from_address: election_proxy_address)
      |> with_block(block_10)

    block_11 = insert(:block, number: 10_782_720, timestamp: ~U[2022-01-06 17:42:43.162804Z])

    transaction_11 =
      :transaction
      |> insert(from_address: election_proxy_address)
      |> with_block(block_11)

    # group active votes
    insert(:celo_validator_group_votes, %{
      block_hash: block_6.hash,
      group_hash: group_address_hash,
      previous_block_active_votes: 650
    })

    insert(:celo_validator_group_votes, %{
      block_hash: block_7.hash,
      group_hash: group_address_hash,
      previous_block_active_votes: 730
    })

    insert(:celo_validator_group_votes, %{
      block_hash: block_8.hash,
      group_hash: group_address_hash,
      previous_block_active_votes: 1000
    })

    insert(:celo_validator_group_votes, %{
      block_hash: block_9.hash,
      group_hash: group_address_hash,
      previous_block_active_votes: 450
    })

    insert(:celo_validator_group_votes, %{
      block_hash: block_10.hash,
      group_hash: group_address_hash,
      previous_block_active_votes: 206
    })

    insert(:celo_validator_group_votes, %{
      block_hash: block_11.hash,
      group_hash: group_address_hash,
      previous_block_active_votes: 283
    })

    # group rewards distributed
    insert(:log,
      address: election_proxy_address,
      block: transaction_6.block,
      block_number: transaction_6.block_number,
      data: Chain.raw_abi_encode_integers([80]),
      first_topic: epoch_rewards_distributed_to_voters,
      second_topic: to_string(group_address),
      index: 2,
      transaction: transaction_6
    )

    insert(:log,
      address: election_proxy_address,
      block: transaction_7.block,
      block_number: transaction_7.block_number,
      data: Chain.raw_abi_encode_integers([20]),
      first_topic: epoch_rewards_distributed_to_voters,
      second_topic: to_string(group_address),
      index: 2,
      transaction: transaction_7
    )

    insert(:log,
      address: election_proxy_address,
      block: transaction_8.block,
      block_number: transaction_8.block_number,
      data: Chain.raw_abi_encode_integers([100]),
      first_topic: epoch_rewards_distributed_to_voters,
      second_topic: to_string(group_address),
      index: 2,
      transaction: transaction_8
    )

    insert(:log,
      address: election_proxy_address,
      block: transaction_9.block,
      block_number: transaction_9.block_number,
      data: Chain.raw_abi_encode_integers([80]),
      first_topic: epoch_rewards_distributed_to_voters,
      second_topic: to_string(group_address),
      index: 2,
      transaction: transaction_9
    )

    insert(:log,
      address: election_proxy_address,
      block: transaction_10.block,
      block_number: transaction_10.block_number,
      data: Chain.raw_abi_encode_integers([77]),
      first_topic: epoch_rewards_distributed_to_voters,
      second_topic: to_string(group_address),
      index: 2,
      transaction: transaction_10
    )

    insert(:log,
      address: election_proxy_address,
      block: transaction_11.block,
      block_number: transaction_11.block_number,
      data: Chain.raw_abi_encode_integers([67]),
      first_topic: epoch_rewards_distributed_to_voters,
      second_topic: to_string(group_address),
      index: 2,
      transaction: transaction_11
    )

    {voter_address_1_hash, group_address_hash}
  end
end
