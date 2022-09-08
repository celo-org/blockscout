defmodule Explorer.Chain.Events.Listener do
  @moduledoc """
  Listens and publishes events
  """

  @source Application.get_env(:explorer, __MODULE__)[:event_source]
  use @source
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, nil, {:continue, :listen_to_source}}
  end

  def handle_continue(:listen_to_source, _state) do
    state = @source.setup_source()
    {:noreply, state}
  end

  defp broadcast({:chain_event, event_type} = event) do
    Logger.info("Listener Received event type - #{event_type}")
    Registry.dispatch(Registry.ChainEvents, event_type, fn entries ->
      for {pid, _registered_val} <- entries do
        send(pid, event)
      end
    end)
  end

  defp broadcast({:chain_event, event_type, broadcast_type, _data} = event) do
    Logger.info("Listener Received event type - #{event_type}")
    Registry.dispatch(Registry.ChainEvents, {event_type, broadcast_type}, fn entries ->
      for {pid, _registered_val} <- entries do
        send(pid, event)
      end
    end)
  end
end
