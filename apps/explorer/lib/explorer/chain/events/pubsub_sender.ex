defmodule Explorer.Chain.Events.PubSubSender do
  @moduledoc """
  Sends events via Phoenix.PubSub / PG2
  """
  require Logger

  @max_payload 7500
  @pubsub_topic "blockscout_chain_event"

  def send_data(event_type) do
    payload = encode_payload({:chain_event, event_type})
    send_notify(payload)
  end

  def send_data(_event_type, :catchup, _event_data), do: :ok

  def send_data(event_type, broadcast_type, event_data) do
    payload = encode_payload({:chain_event, event_type, broadcast_type, event_data})
    send_notify(payload)
  end

  defp encode_payload(payload) do
    payload
    |> :erlang.term_to_binary([:compressed])
  end

  defp send_notify(payload) do
    payload_size = byte_size(payload)

    if payload_size < @max_payload do
      Logger.info("Send #{payload_size} over pubsub")
    else
      Logger.warn("Notification can't be sent, payload size #{payload_size} exceeds the limit of #{@max_payload}.")
    end
  end
end
