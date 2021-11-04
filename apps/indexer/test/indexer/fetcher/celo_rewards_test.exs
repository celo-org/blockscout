defmodule Indexer.Fetcher.CeloVoterRewardsTest do
  # MUST be `async: false` so that {:shared, pid} is set for connection to allow CoinBalanceFetcher's self-send to have
  # connection allowed immediately.
  use EthereumJSONRPC.Case, async: false
  use Explorer.DataCase

  import EthereumJSONRPC, only: [integer_to_quantity: 1]
  import Mox

  alias Explorer.Chain
  alias Explorer.Chain.{Block, Hash, Wei}
  alias Indexer.BufferedTask
  alias Indexer.Fetcher.CeloVoterRewards

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

      expect(EthereumJSONRPC.Mox, :json_rpc, fn [
                                                  %{
                                                    id: id,
                                                    jsonrpc: "2.0",
                                                    method: "eth_call",
                                                    params: [
                                                      %{
                                                        data: "0x853db3230000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000c45706f6368526577617264730000000000000000000000000000000000000000",
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

      expect(EthereumJSONRPC.Mox, :json_rpc, fn [
                                                  %{
                                                    id: id,
                                                    jsonrpc: "2.0",
                                                    method: "eth_call",
                                                    params: [%{data: "0x64347043", to: _}, _]
                                                  }
                                                ],
                                                _ ->
        {
          :ok,
          [
            %{
              id: id,
              jsonrpc: "2.0",
              result: "0x00000000000000000000000000000000000000000000000b24d1d64bfe92e4b100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f1c59e289d2d46d8f4000000000000000000000000000000000000000000000000f793108be48879b3"
            }
          ]
        }
      end)

      assert [%{address_hash: %Explorer.Chain.Hash{byte_count: 20, bytes: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2>>}, block_number: 0, carbon_offsetting_target_epoch_rewards: 17839620741965314483, community_target_epoch_rewards: 4459905185491328620788, retries_count: 0, validator_target_epoch_rewards: 205567322088184931505, voter_target_epoch_rewards: 0}]
             = CeloVoterRewards.fetch_from_blockchain([%{address_hash: address_hash(), block_number: block_number, retries_count: 0}])
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
