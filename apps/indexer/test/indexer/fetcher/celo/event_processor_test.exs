defmodule Indexer.Fetcher.EventProcessorTest do
  use EthereumJSONRPC.Case
  use Explorer.DataCase, async: true

  import Mox

  describe "enqueue/3" do
    setup do
      # start the process
      #

      Indexer.Fetcher.EventProcessor.Supervisor.Case.start_supervised!()
      :ok
    end

    test "enqueues tracked events" do

      assert true, "hello"
    end

    test "doesn't include untracked events" do
      assert true, "goodbye"
    end
  end
end