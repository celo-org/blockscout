defmodule Indexer.Fetcher.CeloEpochDataTest do
  use EthereumJSONRPC.Case, async: false
  use Explorer.DataCase

  import Ecto.Query
  import Explorer.Celo.CacheHelper
  import Explorer.Factory
  import Mox

  alias Explorer.Celo.ContractEvents.Common.TransferEvent
  alias Explorer.Celo.ContractEvents.Election.ValidatorGroupVoteActivatedEvent
  alias Explorer.Celo.ContractEvents.Validators.ValidatorEpochPaymentDistributedEvent
  alias Explorer.Chain.{Address, Block, CeloElectionRewards, CeloEpochRewards, CeloPendingEpochOperation, Wei}
  alias Indexer.Fetcher.CeloEpochData, as: CeloEpochDataFetcher

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
        variant: EthereumJSONRPPC.Parity
      ]
    }
  end

  describe "async_fetch for voter rewards" do
    setup [:save_voter_contract_events_and_start_fetcher, :setup_votes_mox]

    test "with consensus block without reward", context do
      CeloEpochDataFetcher.async_fetch([
        %{
          block_hash: context.last_block_in_epoch_hash,
          block_number: context.last_block_in_epoch_number,
          block_timestamp: DateTime.utc_now()
        }
      ])

      wait_for_results(fn ->
        reward = Repo.one!(from(rewards in CeloElectionRewards))

        {:ok, amount_in_wei} = Wei.cast(4_503_599_627_369_846)
        assert reward.reward_type == "voter"
        assert reward.block_number == context.last_block_in_epoch_number
        assert reward.amount == amount_in_wei
      end)

      # Terminates the process so it finishes all Ecto processes.
      GenServer.stop(context.pid)
    end
  end

  describe "async_fetch for epoch rewards" do
    setup [:save_voter_contract_events_and_start_fetcher, :setup_votes_mox, :setup_epoch_mox]

    test "saves epoch reward to db and deletes pending operation", context do
      CeloEpochDataFetcher.async_fetch([
        %{
          block_hash: context.last_block_in_epoch_hash,
          block_number: context.last_block_in_epoch_number,
          block_timestamp: DateTime.utc_now()
        }
      ])

      wait_for_results(fn ->
        assert Repo.one!(from(rewards in CeloEpochRewards))
        assert count(CeloPendingEpochOperation)
      end)

      # Terminates the process so it finishes all Ecto processes.
      GenServer.stop(context.pid)
    end
  end

  describe "init/2" do
    test "buffers unindexed epoch blocks", %{
      json_rpc_named_arguments: json_rpc_named_arguments
    } do
      block = insert(:block)
      insert(:celo_pending_epoch_operations, block_number: block.number)

      assert CeloEpochDataFetcher.init(
               [],
               fn block_number, acc -> [block_number | acc] end,
               json_rpc_named_arguments
             ) == [%{block_hash: block.hash, block_number: block.number, block_timestamp: block.timestamp}]
    end

    test "does not buffer blocks with fetched rewards", %{
      json_rpc_named_arguments: json_rpc_named_arguments
    } do
      block = insert(:block)
      insert(:celo_pending_epoch_operations, block_number: block.number, fetch_epoch_data: false)

      assert CeloEpochDataFetcher.init(
               [],
               fn block_number, acc -> [block_number | acc] end,
               json_rpc_named_arguments
             ) == []
    end
  end

  describe "get_voter_rewards, when voter rewards are passed" do
    test "it returns the argument" do
      argument = %{
        voter_rewards: "does not matter"
      }

      assert CeloEpochDataFetcher.get_voter_rewards(argument) == argument
    end
  end

  describe "get_validator_and_group_rewards, when no validator and group rewards are passed" do
    setup [:save_validator_and_group_contract_events]

    test "it fetches them from the db for a block", context do
      assert CeloEpochDataFetcher.get_validator_and_group_rewards(%{
               block_number: context.block_number,
               block_timestamp: context.block_timestamp
             }) == %{
               block_number: context.block_number,
               block_timestamp: context.block_timestamp,
               validator_rewards: [
                 %{
                   account_hash: context.validator_1_hash,
                   amount: 100_000,
                   associated_account_hash: context.group_hash,
                   block_number: context.block_number,
                   block_timestamp: context.block_timestamp,
                   reward_type: "validator"
                 },
                 %{
                   account_hash: context.validator_2_hash,
                   amount: 200_000,
                   associated_account_hash: context.group_hash,
                   block_number: context.block_number,
                   block_timestamp: context.block_timestamp,
                   reward_type: "validator"
                 }
               ],
               group_rewards: [
                 %{
                   account_hash: context.group_hash,
                   amount: 300_000,
                   associated_account_hash: context.validator_1_hash,
                   block_number: context.block_number,
                   block_timestamp: context.block_timestamp,
                   reward_type: "group"
                 },
                 %{
                   account_hash: context.group_hash,
                   amount: 300_000,
                   associated_account_hash: context.validator_2_hash,
                   block_number: context.block_number,
                   block_timestamp: context.block_timestamp,
                   reward_type: "group"
                 }
               ]
             }
    end
  end

  describe "get_validator_and_group_rewards, when only validator rewards are passed" do
    setup [:save_validator_and_group_contract_events]

    test "it fetches them from the db for a block", context do
      assert CeloEpochDataFetcher.get_validator_and_group_rewards(%{
               block_number: context.block_number,
               block_timestamp: context.block_timestamp,
               validator_rewards: [
                 %{
                   account_hash: context.validator_1_hash,
                   amount: 100_000,
                   associated_account_hash: context.group_hash,
                   block_number: context.block_number,
                   block_timestamp: context.block_timestamp,
                   reward_type: "validator"
                 },
                 %{
                   account_hash: context.validator_2_hash,
                   amount: 200_000,
                   associated_account_hash: context.group_hash,
                   block_number: context.block_number,
                   block_timestamp: context.block_timestamp,
                   reward_type: "validator"
                 }
               ]
             }) == %{
               block_number: context.block_number,
               block_timestamp: context.block_timestamp,
               group_rewards: [
                 %{
                   account_hash: context.group_hash,
                   amount: 300_000,
                   associated_account_hash: context.validator_1_hash,
                   block_number: context.block_number,
                   block_timestamp: context.block_timestamp,
                   reward_type: "group"
                 },
                 %{
                   account_hash: context.group_hash,
                   amount: 300_000,
                   associated_account_hash: context.validator_2_hash,
                   block_number: context.block_number,
                   block_timestamp: context.block_timestamp,
                   reward_type: "group"
                 }
               ],
               validator_rewards: [
                 %{
                   account_hash: context.validator_1_hash,
                   amount: 100_000,
                   associated_account_hash: context.group_hash,
                   block_number: context.block_number,
                   block_timestamp: context.block_timestamp,
                   reward_type: "validator"
                 },
                 %{
                   account_hash: context.validator_2_hash,
                   amount: 200_000,
                   associated_account_hash: context.group_hash,
                   block_number: context.block_number,
                   block_timestamp: context.block_timestamp,
                   reward_type: "validator"
                 }
               ]
             }
    end
  end

  describe "get_validator_and_group_rewards, when validator and group rewards are passed" do
    test "it returns the argument" do
      argument = %{
        group_rewards: "does not",
        validator_rewards: "matter"
      }

      assert CeloEpochDataFetcher.get_validator_and_group_rewards(argument) == argument
    end
  end

  describe "get_epoch_rewards with reserve bolster event" do
    setup [:save_reserve_bolster_events, :setup_epoch_mox]

    test "it fetches data with reserve bolster", %{block: %{number: block_number, hash: block_hash}} do
      assert CeloEpochDataFetcher.get_epoch_rewards(%{block_number: block_number, block_hash: block_hash}) == %{
               block_hash: block_hash,
               block_number: block_number,
               epoch_rewards: %{
                 block_hash: block_hash,
                 block_number: block_number,
                 carbon_offsetting_target_epoch_rewards: 62_225_632_760_255_012_269,
                 community_target_epoch_rewards: 15_556_408_190_063_753_067_479,
                 electable_validators_max: 110,
                 epoch_number: 10,
                 gold_total_supply: 600_363_049_982_598_326_620_386_513,
                 reserve_bolster: 18_173_469_592_702_214_806_939,
                 reserve_gold_balance: 115_255_226_249_038_379_930_471_272,
                 rewards_multiplier: 1_000_741_854_737_500_000_000_000,
                 rewards_multiplier_max: 2_000_000_000_000_000_000_000_000,
                 rewards_multiplier_over: 5_000_000_000_000_000_000_000_000,
                 rewards_multiplier_under: 500_000_000_000_000_000_000_000,
                 stable_usd_total_supply: 5_182_985_086_049_091_467_996_121,
                 target_total_supply: 601_017_204_041_941_484_863_859_293,
                 target_voting_fraction: 500_000_000_000_000_000_000_000,
                 target_voting_yield: 160_000_000_000_000_000_000,
                 target_voting_yield_adjustment_factor: 0,
                 target_voting_yield_max: 500_000_000_000_000_000_000,
                 total_locked_gold: 316_279_462_377_767_975_674_883_803,
                 total_non_voting: 22_643_903_944_557_354_402_445_358,
                 total_votes: 293_635_558_433_210_621_272_438_445,
                 validator_target_epoch_rewards: 205_631_887_959_760_273_971,
                 voter_target_epoch_rewards: 26_043_810_141_454_976_793_003,
                 voting_fraction: 410_303_431_329_291_024_629_586
               }
             }
    end
  end

  describe "get_epoch_rewards without reserve bolster event" do
    setup [:setup_epoch_mox]

    test "it fetches data without reserve bolster", %{block: %{number: block_number, hash: block_hash}} do
      assert CeloEpochDataFetcher.get_epoch_rewards(%{block_number: block_number, block_hash: block_hash}) == %{
               block_hash: block_hash,
               block_number: block_number,
               epoch_rewards: %{
                 block_hash: block_hash,
                 block_number: block_number,
                 carbon_offsetting_target_epoch_rewards: 62_225_632_760_255_012_269,
                 community_target_epoch_rewards: 15_556_408_190_063_753_067_479,
                 electable_validators_max: 110,
                 epoch_number: 10,
                 gold_total_supply: 600_363_049_982_598_326_620_386_513,
                 reserve_bolster: 0,
                 reserve_gold_balance: 115_255_226_249_038_379_930_471_272,
                 rewards_multiplier: 1_000_741_854_737_500_000_000_000,
                 rewards_multiplier_max: 2_000_000_000_000_000_000_000_000,
                 rewards_multiplier_over: 5_000_000_000_000_000_000_000_000,
                 rewards_multiplier_under: 500_000_000_000_000_000_000_000,
                 stable_usd_total_supply: 5_182_985_086_049_091_467_996_121,
                 target_total_supply: 601_017_204_041_941_484_863_859_293,
                 target_voting_fraction: 500_000_000_000_000_000_000_000,
                 target_voting_yield: 160_000_000_000_000_000_000,
                 target_voting_yield_adjustment_factor: 0,
                 target_voting_yield_max: 500_000_000_000_000_000_000,
                 total_locked_gold: 316_279_462_377_767_975_674_883_803,
                 total_non_voting: 22_643_903_944_557_354_402_445_358,
                 total_votes: 293_635_558_433_210_621_272_438_445,
                 validator_target_epoch_rewards: 205_631_887_959_760_273_971,
                 voter_target_epoch_rewards: 26_043_810_141_454_976_793_003,
                 voting_fraction: 410_303_431_329_291_024_629_586
               }
             }
    end
  end

  describe "import_items/1" do
    test "saves rewards" do
      %Address{hash: voter_hash} = insert(:address)
      %Address{hash: validator_hash} = insert(:address)
      %Address{hash: group_hash} = insert(:address)

      %Block{hash: block_hash, number: block_number} = insert(:block, number: 10_679_040)
      insert(:celo_pending_epoch_operations, block_number: block_number)
      insert(:celo_account, address: group_hash)
      insert(:celo_account, address: validator_hash)

      input = %{
        block_number: block_number,
        epoch_rewards: %{
          block_hash: block_hash,
          block_number: block_number,
          carbon_offsetting_target_epoch_rewards: 62_225_632_760_255_012_269,
          community_target_epoch_rewards: 15_556_408_190_063_753_067_479,
          electable_validators_max: 110,
          epoch_number: 10,
          gold_total_supply: 600_363_049_982_598_326_620_386_513,
          reserve_gold_balance: 115_255_226_249_038_379_930_471_272,
          rewards_multiplier: 1_000_741_854_737_500_000_000_000,
          rewards_multiplier_max: 2_000_000_000_000_000_000_000_000,
          rewards_multiplier_over: 5_000_000_000_000_000_000_000_000,
          rewards_multiplier_under: 500_000_000_000_000_000_000_000,
          stable_usd_total_supply: 5_182_985_086_049_091_467_996_121,
          target_total_supply: 601_017_204_041_941_484_863_859_293,
          target_voting_fraction: 500_000_000_000_000_000_000_000,
          target_voting_yield: 160_000_000_000_000_000_000,
          target_voting_yield_adjustment_factor: 0,
          target_voting_yield_max: 500_000_000_000_000_000_000,
          total_locked_gold: 316_279_462_377_767_975_674_883_803,
          total_non_voting: 22_643_903_944_557_354_402_445_358,
          total_votes: 293_635_558_433_210_621_272_438_445,
          validator_target_epoch_rewards: 205_631_887_959_760_273_971,
          voter_target_epoch_rewards: 26_043_810_141_454_976_793_003,
          voting_fraction: 410_303_431_329_291_024_629_586,
          reserve_bolster: 123_456_789
        },
        voter_rewards: [
          %{
            account_hash: voter_hash,
            amount: 4_503_599_627_369_846,
            associated_account_hash: group_hash,
            block_number: block_number,
            block_timestamp: ~U[2022-05-10 14:18:54.093055Z],
            reward_type: "voter"
          }
        ],
        validator_rewards: [
          %{
            account_hash: validator_hash,
            amount: 4_503_599_627_369_846,
            associated_account_hash: group_hash,
            block_number: block_number,
            block_timestamp: ~U[2022-05-10 14:18:54.093055Z],
            reward_type: "validator"
          }
        ],
        group_rewards: [
          %{
            account_hash: group_hash,
            amount: 4_503_599_627_369_846,
            associated_account_hash: validator_hash,
            block_number: block_number,
            block_timestamp: ~U[2022-05-10 14:18:54.093055Z],
            reward_type: "group"
          }
        ]
      }

      assert CeloEpochDataFetcher.import_items(input) == :ok
    end

    test "with missing data removes rewards type" do
      %Block{number: block_number} = insert(:block, number: 10_679_040)

      assert CeloEpochDataFetcher.import_items(%{
               block_number: block_number,
               voter_rewards: [%{block_number: block_number}]
             }) == %{block_number: block_number}
    end
  end

  defp setup_votes_mox(context) do
    set_test_addresses(%{
      "Election" => "0x8d6677192144292870907e3fa8a5527fe55a7ff6"
    })

    expect(
      EthereumJSONRPC.Mox,
      :json_rpc,
      fn [
           %{
             id: getActiveVotesForGroupByAccount,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: _, to: _}, _]
           }
         ],
         _second_to_last_block_in_epoch_number_number ->
        {
          :ok,
          [
            %{
              id: getActiveVotesForGroupByAccount,
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
             id: getActiveVotesForGroupByAccount,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: _, to: _}, _]
           }
         ],
         _last_block_in_epoch_number_number ->
        {
          :ok,
          [
            %{
              id: getActiveVotesForGroupByAccount,
              jsonrpc: "2.0",
              result: "0x00000000000000000000000000000000000000000002bcd397d61e026fd24890"
            }
          ]
        }
      end
    )

    context
  end

  defp save_validator_and_group_contract_events(context) do
    %Address{hash: validator_1_hash} = insert(:address)
    %Address{hash: validator_2_hash} = insert(:address)
    %Address{hash: group_hash} = insert(:address)
    %Explorer.Chain.CeloCoreContract{address_hash: contract_hash} = insert(:core_contract)

    %Block{number: block_number, timestamp: block_timestamp} = block = insert(:block, number: 10_679_040)

    log_1 = insert(:log, block: block, index: 1)
    log_2 = insert(:log, block: block, index: 2)
    insert(:celo_account, address: group_hash)

    insert(:contract_event, %{
      event: %ValidatorEpochPaymentDistributedEvent{
        __block_number: block_number,
        __contract_address_hash: contract_hash,
        __log_index: log_1.index,
        validator: validator_1_hash,
        validator_payment: 100_000,
        group: group_hash,
        group_payment: 300_000
      }
    })

    insert(:contract_event, %{
      event: %ValidatorEpochPaymentDistributedEvent{
        __block_number: block_number,
        __contract_address_hash: contract_hash,
        __log_index: log_2.index,
        validator: validator_2_hash,
        validator_payment: 200_000,
        group: group_hash,
        group_payment: 300_000
      }
    })

    Map.merge(context, %{
      block_number: block_number,
      block_timestamp: block_timestamp,
      group_hash: group_hash,
      validator_1_hash: validator_1_hash,
      validator_2_hash: validator_2_hash
    })
  end

  def save_reserve_bolster_events(context) do
    gold_token_address = "0x471ece3750da237f93b8e339c536989b8978a438"
    reserve_address = "0x9380fa34fd9e4fd14c06305fd7b6199089ed4eb9"

    insert(
      :core_contract,
      address_hash: gold_token_address,
      name: "GoldToken"
    )

    insert(
      :core_contract,
      address_hash: reserve_address,
      name: "Reserve"
    )

    block = insert(:block, number: 172_800)
    log = insert(:log, block: block)

    insert(:celo_pending_epoch_operations, block_number: block.number)

    insert(:contract_event, %{
      event: %TransferEvent{
        __block_number: block.number,
        __contract_address_hash: gold_token_address,
        __log_index: log.index,
        value: 18_173_469_592_702_214_806_939,
        from: "0x0000000000000000000000000000000000000000",
        to: reserve_address
      }
    })

    Map.merge(context, %{
      block: block
    })
  end

  defp save_voter_contract_events_and_start_fetcher(context) do
    pid =
      CeloEpochDataFetcher.Supervisor.Case.start_supervised!(json_rpc_named_arguments: context.json_rpc_named_arguments)

    %Address{hash: voter_hash} = insert(:address)
    %Address{hash: group_hash} = insert(:address)
    insert(:celo_account, address: group_hash)
    %Explorer.Chain.CeloCoreContract{address_hash: contract_hash} = insert(:core_contract)

    %Block{number: second_to_last_block_in_epoch_number} =
      second_to_last_block_in_epoch = insert(:block, number: 172_799)

    %Block{hash: last_block_in_epoch_hash, number: last_block_in_epoch_number} = insert(:block, number: 172_800)
    log = insert(:log, block: second_to_last_block_in_epoch)

    insert(:celo_pending_epoch_operations, block_number: last_block_in_epoch_number)

    insert(:contract_event, %{
      event: %ValidatorGroupVoteActivatedEvent{
        __block_number: second_to_last_block_in_epoch_number,
        __contract_address_hash: contract_hash,
        __log_index: log.index,
        account: voter_hash,
        group: group_hash,
        units: 10000,
        value: 650
      }
    })

    Map.merge(context, %{
      last_block_in_epoch_hash: last_block_in_epoch_hash,
      last_block_in_epoch_number: last_block_in_epoch_number,
      pid: pid
    })
  end

  defp setup_epoch_mox(context) do
    set_test_addresses(%{
      "EpochRewards" => "0x07f007d389883622ef8d4d347b3f78007f28d8b7",
      "LockedGold" => "0x6cc083aed9e3ebe302a6336dbc7c921c9f03349e",
      "Election" => "0x8d6677192144292870907e3fa8a5527fe55a7ff6",
      "Reserve" => "0x9380fa34fd9e4fd14c06305fd7b6199089ed4eb9",
      "GoldToken" => "0x471ece3750da237f93b8e339c536989b8978a438",
      "StableToken" => "0x765de816845861e75a25fca122bb6898b8b1282a"
    })

    expect(
      EthereumJSONRPC.Mox,
      :json_rpc,
      fn [
           %{
             id: calculateTargetEpochRewards,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x64347043", to: _}, _]
           },
           %{
             id: getTargetGoldTotalSupply,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x5049890f", to: _}, _]
           },
           %{
             id: getRewardsMultiplier,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x0203ab24", to: _}, _]
           },
           %{
             id: getRewardsMultiplierParameters,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x5f396e48", to: _}, _]
           },
           %{
             id: getTargetVotingYieldParameters,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x171af90f", to: _}, _]
           },
           %{
             id: getTargetVotingGoldFraction,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0xae098de2", to: _}, _]
           },
           %{
             id: getVotingGoldFraction,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0xa1b95962", to: _}, _]
           },
           %{
             id: getTotalLockedGold,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x30a61d59", to: _}, _]
           },
           %{
             id: getNonvotingLockedGold,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x807876b7", to: _}, _]
           },
           %{
             id: getTotalVotes,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x9a0e7d66", to: _}, _]
           },
           %{
             id: getElectableValidators,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0xf9f41a7a", to: _}, _]
           },
           %{
             id: getReserveGoldBalance,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x8d9a5e6f", to: _}, _]
           },
           %{
             id: goldTotalSupply,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x18160ddd", to: "0x471ece3750da237f93b8e339c536989b8978a438"}, _]
           },
           %{
             id: stableUSDTotalSupply,
             jsonrpc: "2.0",
             method: "eth_call",
             params: [%{data: "0x18160ddd", to: "0x765de816845861e75a25fca122bb6898b8b1282a"}, _]
           }
         ],
         _ ->
        {
          :ok,
          [
            %{
              id: calculateTargetEpochRewards,
              jsonrpc: "2.0",
              result:
                "0x00000000000000000000000000000000000000000000000b25b7389d6e6f8233000000000000000000000000000000000000000000000583d67889a223c1b9ab00000000000000000000000000000000000000000000034b50882b7adf687bd70000000000000000000000000000000000000000000000035f8ddb4f56e8ddad"
            },
            %{
              id: getTargetGoldTotalSupply,
              jsonrpc: "2.0",
              result: "0x000000000000000000000000000000000000000001f12657ea8a3cbb0ff9aa5d"
            },
            %{
              id: getRewardsMultiplier,
              jsonrpc: "2.0",
              result: "0x00000000000000000000000000000000000000000000d3ea531c462b6d289800"
            },
            %{
              id: getRewardsMultiplierParameters,
              jsonrpc: "2.0",
              result:
                "0x00000000000000000000000000000000000000000001a784379d99db420000000000000000000000000000000000000000000000000069e10de76676d08000000000000000000000000000000000000000000000000422ca8b0a00a425000000"
            },
            %{
              id: getTargetVotingYieldParameters,
              jsonrpc: "2.0",
              result:
                "0x000000000000000000000000000000000000000000000008ac7230489e80000000000000000000000000000000000000000000000000001b1ae4d6e2ef5000000000000000000000000000000000000000000000000000000000000000000000"
            },
            %{
              id: getTargetVotingGoldFraction,
              jsonrpc: "2.0",
              result: "0x0000000000000000000000000000000000000000000069e10de76676d0800000"
            },
            %{
              id: getVotingGoldFraction,
              jsonrpc: "2.0",
              result: "0x0000000000000000000000000000000000000000000056e297f4f13e205a7f52"
            },
            %{
              id: getTotalLockedGold,
              jsonrpc: "2.0",
              result: "0x000000000000000000000000000000000000000001059ec802d92a296076aedb"
            },
            %{
              id: getNonvotingLockedGold,
              jsonrpc: "2.0",
              result: "0x00000000000000000000000000000000000000000012bb087e1546063ebff82e"
            },
            %{
              id: getTotalVotes,
              jsonrpc: "2.0",
              result: "0x000000000000000000000000000000000000000000f2e3bf84c3e42321b6b6ad"
            },
            %{
              id: getElectableValidators,
              jsonrpc: "2.0",
              result:
                "0x0000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000006e"
            },
            %{
              id: getReserveGoldBalance,
              jsonrpc: "2.0",
              result: "0x0000000000000000000000000000000000000000005f563e55a0348825d9cb68"
            },
            %{
              id: goldTotalSupply,
              jsonrpc: "2.0",
              result: "0x000000000000000000000000000000000000000001f09bd2274f90dfe61df4d1"
            },
            %{
              id: stableUSDTotalSupply,
              jsonrpc: "2.0",
              result: "0x00000000000000000000000000000000000000000004498a2f3c39c0d4b5ebd9"
            }
          ]
        }
      end
    )

    context
  end

  defp count(schema) do
    Repo.one!(select(schema, fragment("COUNT(*)")))
  end
end
