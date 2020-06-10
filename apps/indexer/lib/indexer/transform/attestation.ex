defmodule Indexer.Transform.Attestation do
  alias Explorer.Chain.CeloAccount
  @moduledoc """
  Helper functions to parse attestation events.
  """

  def parse(logs) do
    events =
      logs
      |> Enum.filter(&(&1.first_topic == CeloAccount.attestation_completed_event || &1.first_topic == CeloAccount.attestation_issuer_selected_event))
      |> Enum.map(&parse_params/1)

    %{attestation_events: events}
  end

  defp parse_params(%{first_topic: first_topic, second_topic: second_topic, third_topic: third_topic, fourth_topic: fourth_topic, block_number: block_number})
       when not is_nil(second_topic) and not is_nil(third_topic) and not is_nil(fourth_topic) do
    %{
      attestor_hash: truncate_address_hash(fourth_topic),
      attestee_hash: truncate_address_hash(third_topic),
      identifier: second_topic,
      status: status_for(first_topic),
      block_number: block_number
    }
  end

  defp status_for(first_topic) do
    if first_topic == CeloAccount.attestation_completed_event do
      "completed"
    else
      "requested"
    end
  end

  defp truncate_address_hash("0x000000000000000000000000" <> truncated_hash) do
    "0x#{truncated_hash}"
  end
end
