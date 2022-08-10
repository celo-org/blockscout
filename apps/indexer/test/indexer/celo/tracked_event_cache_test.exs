defmodule Indexer.Celo.TrackedEventCacheTest do
  use Explorer.DataCase, async: false
  import Explorer.Factory

  alias Explorer.Chain.Celo.{ContractEventTracking, TrackedContractEvent}
  alias Explorer.Chain.{Log, SmartContract}
  alias Indexer.Celo.TrackedEventCache

  def create_smart_contract do
    contract_abi =
      File.read!("../explorer/test/explorer/chain/celo/lockedgoldabi.json")
      |> Jason.decode!()

    contract_code_info = %{
      bytecode:
        "0x6080604052600436106049576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806360fe47b114604e5780636d4ce63c146078575b600080fd5b348015605957600080fd5b5060766004803603810190808035906020019092919050505060a0565b005b348015608357600080fd5b50608a60aa565b6040518082815260200191505060405180910390f35b8060008190555050565b600080549050905600a165627a7a72305820f65a3adc1cfb055013d1dc37d0fe98676e2a5963677fa7541a10386d163446680029",
      tx_input:
        "0x608060405234801561001057600080fd5b5060df8061001f6000396000f3006080604052600436106049576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806360fe47b114604e5780636d4ce63c146078575b600080fd5b348015605957600080fd5b5060766004803603810190808035906020019092919050505060a0565b005b348015608357600080fd5b50608a60aa565b6040518082815260200191505060405180910390f35b8060008190555050565b600080549050905600a165627a7a72305820853a985d0a4b20246785fc2f0357c202faa3db289980a48737180f358f9ddc3c0029",
      name: "ContractEventTrackingTestContract",
      source_code: """
      //code isn't important for these tests
      """,
      abi: contract_abi,
      version: "v0.4.24+commit.e67f0147",
      optimized: false
    }

    %SmartContract{
      address_hash: insert(:address, contract_code: contract_code_info.bytecode, verified: true).hash,
      compiler_version: contract_code_info.version,
      name: contract_code_info.name,
      contract_source_code: contract_code_info.source_code,
      optimization: contract_code_info.optimized,
      abi: contract_code_info.abi
    }
    |> insert()
  end

  def add_trackings(event_topics) do
    smart_contract = create_smart_contract()

    event_topics
    |> Enum.each( fn topic ->
      {:ok, tracking} =
        smart_contract
        |> ContractEventTracking.from_event_topic(topic)
        |> Repo.insert()
    end)

    smart_contract
  end
  @gold_unlocked_topic "0xb1a3aef2a332070da206ad1868a5e327f5aa5144e00e9a7b40717c153158a588"

  describe "populates cache" do

    test "populates ets with cached events" do
      smart_contract = add_trackings([@gold_unlocked_topic])

      cache_pid = start_supervised!( {TrackedEventCache, [%{}, []]})

      #force handle_continue to complete before continuing with test
      _ = :sys.get_state(cache_pid)

      cached_event = :ets.lookup(TrackedEventCache, {@gold_unlocked_topic, smart_contract.address_hash |> to_string()})
      refute cached_event == []

    end

    test "rebuilds cache on command" do
    end
  end

  describe "filters events" do
    test "filters out untracked events" do
    end
  end
end