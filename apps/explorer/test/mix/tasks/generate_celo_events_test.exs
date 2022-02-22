defmodule Explorer.GenerateCeloEventsTest do
  use Explorer.DataCase
  alias Mix.Tasks.GenerateCeloEvents

  describe "generate_topic" do
    test "should match known topics from known abis" do
      test_event_def =  %{
        "anonymous" => false,
        "inputs" => [
          %{"indexed" => true, "name" => "account", "type" => "address"},
          %{"indexed" => true, "name" => "group", "type" => "address"},
          %{"indexed" => false, "name" => "value", "type" => "uint256"},
          %{"indexed" => false, "name" => "units", "type" => "uint256"}
        ],
        "name" => "ValidatorGroupVoteActivated",
        "type" => "event"
      }

      topic = GenerateCeloEvents.generate_topic(test_event_def)
      assert topic == "0x45aac85f38083b18efe2d441a65b9c1ae177c78307cb5a5d4aec8f7dbcaeabfe"
    end
  end
end