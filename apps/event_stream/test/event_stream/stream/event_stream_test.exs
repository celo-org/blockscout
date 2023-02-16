defmodule EventStream.EventStreamTest do
  use ExUnit.Case, async: true
  alias EventStream.ContractEventStream

  alias Explorer.Celo.ContractEvents.EventTransformer
  alias Explorer.Celo.ContractEvents.EventMap
  alias Explorer.Celo.ContractEvents.Election.ValidatorGroupVoteActivatedEvent
  alias Explorer.Chain.Log
  import Mox

  setup do
    on_exit(fn ->
      ContractEventStream.clear()
    end)
  end
  setup :verify_on_exit!


  test "Enqueue pushes events into the buffer" do
    test_events = [1,2,3] |> Enum.map(&(generate_event(&1)))

    ContractEventStream.enqueue(test_events)

    event_buffer = ContractEventStream.clear()

    assert length(event_buffer |> List.flatten()) == 3
  end


  test "Publishes events on tick" do
    test_events = [1,2,3] |> Enum.map(&(generate_event(&1)))
    ContractEventStream.enqueue(test_events)

    EventStream.Publisher.Mock |> expect(:publish, 3, fn _event -> :ok end)

  end
  #random event taken from staging eventstream
  def generate_event(id) do
    %Explorer.Chain.CeloContractEvent{
      block_number: 17777818,
      contract_address_hash: "0x471ece3750da237f93b8e339c536989b8978a438",
      inserted_at: ~U[2023-02-16 14:19:20.260051Z],
      log_index: id,
      name: "Transfer",
      params: %{
        "from" => "\\xb460f9ae1fea4f77107146c1960bb1c978118816",
        "to" => "\\x0ef38e213223805ec1810eebd42153a072a2d89a",
        "value" => 6177463272192542
      },
      topic: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
      transaction_hash: "0x7640d07bdc3b51065169b8f6a4720c2f807716f31e40212d81b41dfe1441668b",
      updated_at: ~U[2023-02-16 14:19:20.260051Z]
    }
  end
end