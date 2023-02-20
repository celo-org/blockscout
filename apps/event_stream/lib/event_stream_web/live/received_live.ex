defmodule EventStream.ReceivedLive do
  use EventStream, :live_view

  alias EventStream.Subscriptions

  @impl true
  def mount(_params, _session, socket) do
    Subscriptions.subscribe()

    events = []

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
