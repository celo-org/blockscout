defmodule Indexer.Fetcher.EventProcessorTest do
  use Explorer.DataCase, async: false

  import Indexer.Celo.TrackedEventSupport

  alias Indexer.Fetcher.EventProcessor
  alias Indexer.Celo.TrackedEventCache

  describe "enqueue/3" do
    ## end to end test - enqueue to import
    test "buffers tracked events and imports" do
      smart_contract = add_trackings([gold_relocked_topic()])
      cache_pid = start_supervised!( {TrackedEventCache, [%{}, []]})
      _ = :sys.get_state(cache_pid)

      pid = Indexer.Fetcher.EventProcessor.Supervisor.Case.start_supervised!()
      logs = gold_relocked_logs(smart_contract.address_hash)

      EventProcessor.enqueue_logs(logs)
       require IEx; IEx.pry
      # generate some logs
      # enqueue the logs to the event processor
      # assert that they are in the database
      assert true, "hello"
    end
  end
end