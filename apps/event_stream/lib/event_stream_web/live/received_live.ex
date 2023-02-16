defmodule EventStream.ReceivedLive do
  use EventStream, :live_view

  alias EventStream.Subscriptions

  @impl true
  def mount(_params, _session, socket) do
    Subscriptions.subscribe()

    events = ["{\"block_number\":17777818,\"contract_address_hash\":\"0x471ece3750da237f93b8e339c536989b8978a438\",\"log_index\":2,\"name\":\"Transfer\",\"params\":{\"from\":\"0xb460f9ae1fea4f77107146c1960bb1c978118816\",\"to\":\"0x0ef38e213223805ec1810eebd42153a072a2d89a\",\"value\":6177463272192542},\"topic\":\"0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef\",\"transaction_hash\":\"0x7640d07bdc3b51065169b8f6a4720c2f807716f31e40212d81b41dfe1441668b\"}"]
    assigns =
      socket
      |> assign(query: "", results: %{})
      |> assign(events: events)
    {:ok,  assigns}
  end

  @impl true
  def handle_info({:chain_event, _type, :realtime, data}, socket = %{assigns: %{events: events}}) do
    socket = socket |> assign(events: events ++ data)

    {:noreply, socket}
  end

end
