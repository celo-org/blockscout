defmodule Indexer.Fetcher.CeloEpochRewardsTest do
  # MUST be `async: false` so that {:shared, pid} is set for connection to allow CoinBalanceFetcher's self-send to have
  # connection allowed immediately.
  use EthereumJSONRPC.Case, async: false
  use Explorer.DataCase

  import EthereumJSONRPC, only: [integer_to_quantity: 1]
  import Mox

  alias Explorer.Chain
  alias Explorer.Chain.{Block, CeloEpochRewards, CeloPendingEpochOperation, Hash, Wei}
  alias Indexer.BufferedTask
  alias Indexer.Fetcher.CeloEpochRewards, as: CeloEpochRewardsFetcher

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
      insert(:celo_pending_epoch_operations, block_hash: block.hash, fetch_epoch_rewards: true)

      assert CeloEpochRewardsFetcher.init(
               [],
               fn block_number, acc -> [block_number | acc] end,
               json_rpc_named_arguments
             ) == [block.number]
    end

    @tag :no_geth
    test "does not buffer blocks with fetched internal transactions", %{
      json_rpc_named_arguments: json_rpc_named_arguments
    } do
      block = insert(:block)
      insert(:celo_pending_epoch_operations, block_hash: block.hash, fetch_epoch_rewards: false)

      assert CeloEpochRewardsFetcher.init(
               [],
               fn block_number, acc -> [block_number | acc] end,
               json_rpc_named_arguments
             ) == []
    end
  end

  describe "fetch_from_blockchain/1" do
    setup do
      block = insert(:block)

      %{block: block}
    end

    test "fetches epoch data from blockchain", %{
      block: %Block{
        hash: block_hash,
        number: block_number,
        miner_hash: %Hash{bytes: miner_hash_bytes} = miner_hash,
        consensus: true
      },
      json_rpc_named_arguments: json_rpc_named_arguments
    } do
      block_quantity = integer_to_quantity(block_number)

      # getting the EpochRewards contract
      expect(EthereumJSONRPC.Mox, :json_rpc, 7, fn [
                                                     %{
                                                       id: id,
                                                       jsonrpc: "2.0",
                                                       method: "eth_call",
                                                       params: [
                                                         %{
                                                           data:
                                                             "0x853db3230000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000c45706f6368526577617264730000000000000000000000000000000000000000",
                                                           to: "0x000000000000000000000000000000000000ce10"
                                                         },
                                                         _
                                                       ]
                                                     }
                                                   ],
                                                   _ ->
        {
          :ok,
          [
            %{
              id: id,
              jsonrpc: "2.0",
              result: "0x00000000000000000000000007f007d389883622ef8d4d347b3f78007f28d8b7"
            }
          ]
        }
      end)

      # getting the LockedGold contract
      expect(EthereumJSONRPC.Mox, :json_rpc, 2, fn [
                                                     %{
                                                       id: id,
                                                       jsonrpc: "2.0",
                                                       method: "eth_call",
                                                       params: [
                                                         %{
                                                           data:
                                                             "0x853db3230000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000a4c6f636b6564476f6c6400000000000000000000000000000000000000000000",
                                                           to: "0x000000000000000000000000000000000000ce10"
                                                         },
                                                         _
                                                       ]
                                                     }
                                                   ],
                                                   _ ->
        {
          :ok,
          [
            %{
              id: id,
              jsonrpc: "2.0",
              result: "0x0000000000000000000000006cc083aed9e3ebe302a6336dbc7c921c9f03349e"
            }
          ]
        }
      end)

      # getting the Election contract
      expect(EthereumJSONRPC.Mox, :json_rpc, 2, fn [
                                                     %{
                                                       id: id,
                                                       jsonrpc: "2.0",
                                                       method: "eth_call",
                                                       params: [
                                                         %{
                                                           data:
                                                             "0x853db32300000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000008456c656374696f6e000000000000000000000000000000000000000000000000",
                                                           to: "0x000000000000000000000000000000000000ce10"
                                                         },
                                                         _
                                                       ]
                                                     }
                                                   ],
                                                   _ ->
        {
          :ok,
          [
            %{
              id: id,
              jsonrpc: "2.0",
              result: "0x0000000000000000000000008d6677192144292870907e3fa8a5527fe55a7ff6"
            }
          ]
        }
      end)

      # getting the Reserve contract
      expect(EthereumJSONRPC.Mox, :json_rpc, fn [
                                                  %{
                                                    id: id,
                                                    jsonrpc: "2.0",
                                                    method: "eth_call",
                                                    params: [
                                                      %{
                                                        data:
                                                          "0x853db323000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000075265736572766500000000000000000000000000000000000000000000000000",
                                                        to: "0x000000000000000000000000000000000000ce10"
                                                      },
                                                      _
                                                    ]
                                                  }
                                                ],
                                                _ ->
        {
          :ok,
          [
            %{
              id: id,
              jsonrpc: "2.0",
              result: "0x0000000000000000000000009380fa34fd9e4fd14c06305fd7b6199089ed4eb9"
            }
          ]
        }
      end)

      # getting the GoldToken contract
      expect(EthereumJSONRPC.Mox, :json_rpc, fn [
                                                  %{
                                                    id: id,
                                                    jsonrpc: "2.0",
                                                    method: "eth_call",
                                                    params: [
                                                      %{
                                                        data:
                                                          "0x853db32300000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000009476f6c64546f6b656e0000000000000000000000000000000000000000000000",
                                                        to: "0x000000000000000000000000000000000000ce10"
                                                      },
                                                      _
                                                    ]
                                                  }
                                                ],
                                                _ ->
        {
          :ok,
          [
            %{
              id: id,
              jsonrpc: "2.0",
              result: "0x000000000000000000000000471ece3750da237f93b8e339c536989b8978a438"
            }
          ]
        }
      end)

      # getting the StableToken contract
      expect(EthereumJSONRPC.Mox, :json_rpc, fn [
                                                  %{
                                                    id: id,
                                                    jsonrpc: "2.0",
                                                    method: "eth_call",
                                                    params: [
                                                      %{
                                                        data:
                                                          "0x853db3230000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000b537461626c65546f6b656e000000000000000000000000000000000000000000",
                                                        to: "0x000000000000000000000000000000000000ce10"
                                                      },
                                                      _
                                                    ]
                                                  }
                                                ],
                                                _ ->
        {
          :ok,
          [
            %{
              id: id,
              jsonrpc: "2.0",
              result: "0x000000000000000000000000765de816845861e75a25fca122bb6898b8b1282a"
            }
          ]
        }
      end)

      expect(
        EthereumJSONRPC.Mox,
        :json_rpc,
        # calculateTargetEpochRewards
        # getTargetGoldTotalSupply
        # getRewardsMultiplier
        # getRewardsMultiplierParameters
        # getTargetVotingYieldParameters
        # getTargetVotingGoldFraction
        # getVotingGoldFraction
        # getTotalLockedGold
        # getNonvotingLockedGold
        # getTotalVotes
        # getElectableValidators
        # getReserveGoldBalance
        # goldTotalSupply
        # stableUSDTotalSupply
        fn [
             %{
               id: id_0,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0x64347043", to: _}, _]
             },
             %{
               id: id_1,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0x5049890f", to: _}, _]
             },
             %{
               id: id_2,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0x0203ab24", to: _}, _]
             },
             %{
               id: id_3,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0x5f396e48", to: _}, _]
             },
             %{
               id: id_4,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0x171af90f", to: _}, _]
             },
             %{
               id: id_5,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0xae098de2", to: _}, _]
             },
             %{
               id: id_6,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0xa1b95962", to: _}, _]
             },
             %{
               id: id_7,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0x30a61d59", to: _}, _]
             },
             %{
               id: id_8,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0x807876b7", to: _}, _]
             },
             %{
               id: id_9,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0x9a0e7d66", to: _}, _]
             },
             %{
               id: id_10,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0xf9f41a7a", to: _}, _]
             },
             %{
               id: id_11,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0x8d9a5e6f", to: _}, _]
             },
             %{
               id: id_12,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0x18160ddd", to: "0x471ece3750da237f93b8e339c536989b8978a438"}, _]
             },
             %{
               id: id_13,
               jsonrpc: "2.0",
               method: "eth_call",
               params: [%{data: "0x18160ddd", to: "0x765de816845861e75a25fca122bb6898b8b1282a"}, _]
             }
           ],
           _ ->
          {
            :ok,
            [
              # calculateTargetEpochRewards
              %{
                id: id_0,
                jsonrpc: "2.0",
                result:
                  "0x00000000000000000000000000000000000000000000000b25b7389d6e6f8233000000000000000000000000000000000000000000000583d67889a223c1b9ab00000000000000000000000000000000000000000000034b50882b7adf687bd70000000000000000000000000000000000000000000000035f8ddb4f56e8ddad"
              },
              # getTargetGoldTotalSupply
              %{
                id: id_1,
                jsonrpc: "2.0",
                result: "0x000000000000000000000000000000000000000001f12657ea8a3cbb0ff9aa5d"
              },
              # getRewardsMultiplier
              %{
                id: id_2,
                jsonrpc: "2.0",
                result: "0x00000000000000000000000000000000000000000000d3ea531c462b6d289800"
              },
              # getRewardsMultiplierParameters
              %{
                id: id_3,
                jsonrpc: "2.0",
                result:
                  "0x00000000000000000000000000000000000000000001a784379d99db420000000000000000000000000000000000000000000000000069e10de76676d08000000000000000000000000000000000000000000000000422ca8b0a00a425000000"
              },
              # getTargetVotingYieldParameters
              %{
                id: id_4,
                jsonrpc: "2.0",
                result:
                  "0x000000000000000000000000000000000000000000000008ac7230489e80000000000000000000000000000000000000000000000000001b1ae4d6e2ef5000000000000000000000000000000000000000000000000000000000000000000000"
              },
              # getTargetVotingGoldFraction
              %{
                id: id_5,
                jsonrpc: "2.0",
                result: "0x0000000000000000000000000000000000000000000069e10de76676d0800000"
              },
              # getVotingGoldFraction
              %{
                id: id_6,
                jsonrpc: "2.0",
                result: "0x0000000000000000000000000000000000000000000056e297f4f13e205a7f52"
              },
              # getTotalLockedGold
              %{
                id: id_7,
                jsonrpc: "2.0",
                result: "0x000000000000000000000000000000000000000001059ec802d92a296076aedb"
              },
              # getNonvotingLockedGold
              %{
                id: id_8,
                jsonrpc: "2.0",
                result: "0x00000000000000000000000000000000000000000012bb087e1546063ebff82e"
              },
              # getTotalVotes
              %{
                id: id_9,
                jsonrpc: "2.0",
                result: "0x000000000000000000000000000000000000000000f2e3bf84c3e42321b6b6ad"
              },
              # getElectableValidators
              %{
                id: id_10,
                jsonrpc: "2.0",
                result:
                  "0x0000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000006e"
              },
              # getReserveGoldBalance
              %{
                id: id_11,
                jsonrpc: "2.0",
                result: "0x0000000000000000000000000000000000000000005f563e55a0348825d9cb68"
              },
              # goldTotalSupply
              %{
                id: id_12,
                jsonrpc: "2.0",
                result: "0x000000000000000000000000000000000000000001f09bd2274f90dfe61df4d1"
              },
              # stableUSDTotalSupply
              %{
                id: id_13,
                jsonrpc: "2.0",
                result: "0x00000000000000000000000000000000000000000004498a2f3c39c0d4b5ebd9"
              }
            ]
          }
        end
      )

      fetched =
        CeloEpochRewardsFetcher.fetch_from_blockchain([
          %{address_hash: address_hash(), block_number: block_number, retries_count: 0}
        ])

      IO.inspect(fetched)

      assert [
               %{
                 address_hash: %Explorer.Chain.Hash{
                   byte_count: 20,
                   bytes: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2>>
                 },
                 block_number: 0,
                 carbon_offsetting_target_epoch_rewards: 62_225_632_760_255_012_269,
                 community_target_epoch_rewards: 15_556_408_190_063_753_067_479,
                 retries_count: 0,
                 validator_target_epoch_rewards: 205_631_887_959_760_273_971,
                 voter_target_epoch_rewards: 26_043_810_141_454_976_793_003,
                 target_total_supply: 601_017_204_041_941_484_863_859_293,
                 rewards_multiplier: 1_000_741_854_737_500_000_000_000,
                 rewards_multiplier_max: 2_000_000_000_000_000_000_000_000,
                 rewards_multiplier_under: 500_000_000_000_000_000_000_000,
                 rewards_multiplier_over: 5_000_000_000_000_000_000_000_000,
                 target_voting_yield: 160_000_000_000_000_000_000,
                 target_voting_yield_adjustment_factor: 0,
                 target_voting_yield_max: 500_000_000_000_000_000_000,
                 target_voting_fraction: 500_000_000_000_000_000_000_000,
                 voting_fraction: 410_303_431_329_291_024_629_586,
                 total_locked_gold: 316_279_462_377_767_975_674_883_803,
                 total_non_voting: 22_643_903_944_557_354_402_445_358,
                 total_votes: 293_635_558_433_210_621_272_438_445,
                 electable_validators_max: 110,
                 reserve_gold_balance: 115_255_226_249_038_379_930_471_272,
                 gold_total_supply: 600_363_049_982_598_326_620_386_513,
                 stable_usd_total_supply: 5_182_985_086_049_091_467_996_121
               }
             ] == fetched
    end
  end

  describe "import_items/1" do
    test "saves epoch rewards and deletes celo pending epoch operations" do
      block = insert(:block, hash: %Explorer.Chain.Hash{
        byte_count: 32,
        bytes: <<252, 154, 78, 156, 195, 203, 115, 134, 25, 196, 0, 181, 189, 239,
          174, 127, 27, 61, 98, 208, 104, 72, 127, 167, 112, 119, 204, 138, 81,
          255, 5, 91>>
      }, number: 9434880)
      insert(:celo_pending_epoch_operations, block_hash: block.hash, fetch_epoch_rewards: true)

      rewards = [
        %{
          address_hash: %Explorer.Chain.Hash{
            byte_count: 20,
            bytes: <<42, 57, 230, 201, 63, 231, 229, 237, 228, 165, 179, 126, 139,
              187, 19, 165, 70, 44, 201, 123>>
          },
          block_hash: block.hash,
          block_number: block.number,
          carbon_offsetting_target_epoch_rewards: 55094655441694756188,
          community_target_epoch_rewards: 13773663860423689047089,
          electable_validators_max: 110,
          epoch_number: 546,
          gold_total_supply: 632725491274706367854422889,
          log_index: 0,
          reserve_gold_balance: 115257993782506057885594247,
          rewards_multiplier: 830935429083244762116865,
          rewards_multiplier_max: 2000000000000000000000000,
          rewards_multiplier_over: 5000000000000000000000000,
          rewards_multiplier_under: 500000000000000000000000,
          stable_usd_total_supply: 102072732704065987635855047,
          target_total_supply: 619940889565364451209200067,
          target_voting_fraction: 600000000000000000000000,
          target_voting_yield: 161241419224794107230,
          target_voting_yield_adjustment_factor: 1127990000000000000,
          target_voting_yield_max: 500000000000000000000,
          total_locked_gold: 316316894443027811324534950,
          total_non_voting: 22643903944557354402445358,
          total_votes: 293672990498470456922089592,
          validator_target_epoch_rewards: 170740156660940704543,
          voter_target_epoch_rewards: 38399789501591793730548,
          voting_fraction: "hey"
        }
      ]

      CeloEpochRewardsFetcher.import_items(rewards)

      assert count(CeloPendingEpochOperation) == 0
      assert count(CeloEpochRewards) == 1
    end
  end

  defp count(schema) do
    Repo.one!(select(schema, fragment("COUNT(*)")))
  end

  defp wait_for_tasks(buffered_task) do
    wait_until(:timer.seconds(10), fn ->
      counts = BufferedTask.debug_count(buffered_task)
      counts.buffer == 0 and counts.tasks == 0
    end)
  end

  defp wait_until(timeout, producer) do
    parent = self()
    ref = make_ref()

    spawn(fn -> do_wait_until(parent, ref, producer) end)

    receive do
      {^ref, :ok} -> :ok
    after
      timeout -> exit(:timeout)
    end
  end

  defp do_wait_until(parent, ref, producer) do
    if producer.() do
      send(parent, {ref, :ok})
    else
      :timer.sleep(100)
      do_wait_until(parent, ref, producer)
    end
  end
end
