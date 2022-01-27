defmodule Indexer.Fetcher.CeloValidatorGroupVotesTest do
  # MUST be `async: false` so that {:shared, pid} is set for connection to allow CoinBalanceFetcher's self-send to have
  # connection allowed immediately.
  use EthereumJSONRPC.Case, async: false
  use Explorer.DataCase

  import EthereumJSONRPC, only: [integer_to_quantity: 1]
  import Explorer.Celo.CacheHelper
  import Mox

  alias Explorer.Celo.Events
  alias Explorer.Chain
  alias Explorer.Chain.{Address, Block, CeloPendingEpochOperation, CeloValidatorGroupVotes, Hash}
  alias Indexer.Fetcher.CeloValidatorGroupVotes, as: CeloValidatorGroupVotesFetcher

  @moduletag :capture_log

  # MUST use global mode because we aren't guaranteed to get `start_supervised`'s pid back fast enough to `allow` it to
  # use expectations and stubs from test's pid.
  setup :set_mox_global

  setup :verify_on_exit!

  setup do
    start_supervised!({Task.Supervisor, name: Indexer.TaskSupervisor})

    # Need to always mock to allow consensus switches to happen on demand and protect from them happening when we don't
    # want them to.
    %{
      json_rpc_named_arguments: [
        transport: EthereumJSONRPC.Mox,
        transport_options: [],
        # Which one does not matter, so pick one
        variant: EthereumJSONRPC.Parity
      ]
    }
  end

  describe "init/2" do
    test "buffers unindexed epoch blocks", %{
      json_rpc_named_arguments: json_rpc_named_arguments
    } do
      block = insert(:block)
      insert(:celo_pending_epoch_operations, block_hash: block.hash)

      assert CeloValidatorGroupVotesFetcher.init(
               [],
               fn block_number, acc -> [block_number | acc] end,
               json_rpc_named_arguments
             ) == [%{block_number: block.number, block_hash: block.hash}]
    end

    @tag :no_geth
    test "does not buffer blocks with fetched epoch rewards", %{
      json_rpc_named_arguments: json_rpc_named_arguments
    } do
      block = insert(:block)
      insert(:celo_pending_epoch_operations, block_hash: block.hash, fetch_validator_group_data: false)

      assert CeloValidatorGroupVotesFetcher.init(
               [],
               fn block_number, acc -> [block_number | acc] end,
               json_rpc_named_arguments
             ) == []
    end
  end

  describe "fetch_from_blockchain/1" do
    test "fetches validator group votes from blockchain", %{
      json_rpc_named_arguments: json_rpc_named_arguments
    } do
      [epoch_rewards_distributed_to_voters] = Events.validator_group_voter_reward_events()
      block_1 = %Block{hash: block_1_hash, number: block_1_number} = insert(:block, number: 172_800)
      block_2 = %Block{hash: block_2_hash, number: block_2_number} = insert(:block, number: 190_080)
      %Address{hash: group_1_hash} = insert(:address)
      %Address{hash: group_2_hash} = insert(:address)
      election_contract_address = insert(:address)

      insert(:log,
        address: election_contract_address,
        block: block_1,
        data: Chain.raw_abi_encode_integers([650, 10000]),
        first_topic: epoch_rewards_distributed_to_voters,
        second_topic: to_string(group_1_hash),
        index: 1
      )

      insert(:log,
        address: election_contract_address,
        block: block_2,
        data: Chain.raw_abi_encode_integers([650, 10000]),
        first_topic: epoch_rewards_distributed_to_voters,
        second_topic: to_string(group_2_hash),
        index: 1
      )

      setup_mox()

      assert CeloValidatorGroupVotesFetcher.fetch_from_blockchain([
               %{block_number: block_1_number, block_hash: block_1_hash, group_hash: group_1_hash},
               %{block_number: block_2_number, block_hash: block_2_hash, group_hash: group_2_hash}
             ]) == [
               %{
                 block_hash: block_1_hash,
                 block_number: block_1_number,
                 group_hash: group_1_hash,
                 previous_block_active_votes: 3_309_559_737_470_045_295_626_384
               },
               %{
                 block_hash: block_2_hash,
                 block_number: block_2_number,
                 group_hash: group_2_hash,
                 previous_block_active_votes: 2_601_552_679_256_724_525_663_215
               }
             ]
    end
  end

  describe "import_items/1" do
    test "saves epoch rewards and deletes celo pending epoch operations" do
      block_1 = %Block{hash: block_1_hash, number: block_1_number} = insert(:block, number: 172_800)
      block_2 = %Block{hash: block_2_hash, number: block_2_number} = insert(:block, number: 190_080)
      %Address{hash: group_1_hash} = insert(:address)
      %Address{hash: group_2_hash} = insert(:address)

      insert(:celo_pending_epoch_operations, block_hash: block_1_hash)
      insert(:celo_pending_epoch_operations, block_hash: block_2_hash, fetch_epoch_rewards: false)

      votes = [
        %{
          block_hash: block_1_hash,
          block_number: block_1_number,
          group_hash: group_1_hash,
          previous_block_active_votes: 3_309_559_737_470_045_295_626_384
        },
        %{
          block_hash: block_2_hash,
          block_number: block_2_number,
          group_hash: group_2_hash,
          previous_block_active_votes: 2_601_552_679_256_724_525_663_215
        }
      ]

      assert count(CeloPendingEpochOperation) == 1
      assert count(CeloValidatorGroupVotes) == 2
    end
  end

  defp count(schema) do
    Repo.one!(select(schema, fragment("COUNT(*)")))
  end

  defp setup_mox() do
    set_test_addresses(%{
      "Election" => "0x8d6677192144292870907e3fa8a5527fe55a7ff6"
    })

    expect(
      EthereumJSONRPC.Mox,
      :json_rpc,
      fn [
           %{
             id: getActiveVotesForGroup,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x926d00ca0000000000000000000000000000000000000000000000000000000000000003", to: _}, _]
           }
         ],
         _ ->
        {
          :ok,
          [
            %{
              id: getActiveVotesForGroup,
              jsonrpc: "2.0",
              result: "0x00000000000000000000000000000000000000000002bcd397c61e026fd24890"
            }
          ]
        }
      end
    )

    expect(
      EthereumJSONRPC.Mox,
      :json_rpc,
      fn [
           %{
             id: getActiveVotesForGroup,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x926d00ca0000000000000000000000000000000000000000000000000000000000000004", to: _}, _]
           }
         ],
         _ ->
        {
          :ok,
          [
            %{
              id: getActiveVotesForGroup,
              jsonrpc: "2.0",
              result: "0x0000000000000000000000000000000000000000000226e6740db72837e5c3ef"
            }
          ]
        }
      end
    )
  end
end
