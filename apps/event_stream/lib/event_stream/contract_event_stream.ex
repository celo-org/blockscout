defmodule EventStream.ContractEventStream do
  @moduledoc """
     Accepts events and pushes them to an external queue (beanstalkd)
  """

  use GenServer
  require Logger
  alias Explorer.Chain.Events.Subscriber
  alias Explorer.Celo.ContractEvents.{EventMap, EventTransformer}
  alias Explorer.Celo.Telemetry

  @doc "Accept a list of events and buffer for sending"
  def enqueue(events) do
    GenServer.cast(__MODULE__, {:enqueue, events})
    {:ok, events}
  end

  @doc "Transform celo contract event to expected json format"
  def transform_event(event) do
    event
    |> EventMap.celo_contract_event_to_concrete_event()
    |> EventTransformer.to_event_stream_format()
  end

  # callbacks

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @flush_interval_ms 5_000
  @subscribed_event_types [:celo_contract_event, :tracked_contract_event]

  @impl true
  def init(buffer) do
    Process.flag(:trap_exit, true)
    timer = Process.send_after(self(), :tick, @flush_interval_ms)

    # subscribe to receive messages from pubsub
    @subscribed_event_types |> Enum.each(&( Subscriber.to(&1)))

    refresh_time = System.get_env("EVENT_STREAM_REFRESH")

    {:ok, %{buffer: buffer, timer: timer}}
  end


#
#  @impl true
#  def handle_continue(:connect_to_beanstalk, state) do
#    # charlist type required for erlang library
#    host = "BEANSTALKD_HOST" |> System.get_env() |> to_charlist()
#
#    {port, _} = "BEANSTALKD_PORT" |> System.get_env() |> Integer.parse()
#    tube = "BEANSTALKD_TUBE" |> System.get_env("default")
#
#    pid = connect_beanstalkd(host, port)
#    {:using, ^tube} = ElixirTalk.use(pid, tube)
#
#    {:noreply, Map.put(state, :beanstalkd_pid, pid)}
#  end

#  defp connect_beanstalkd(host, port) do
#    {:ok, pid} = ElixirTalk.connect(host, port)
#    pid
#  end

  @impl true
  def handle_cast({:enqueue, event}, %{buffer: buffer} = state) do
    {:noreply, %{state | buffer: [event | buffer]}}
  end

  @impl true
  def handle_info(:tick, %{buffer: buffer, timer: timer} = state) do
    Process.cancel_timer(timer)
    failed_events = run(buffer)

    new_timer = Process.send_after(self(), :tick, @flush_interval_ms)

    {:noreply, %{state | buffer: failed_events, timer: new_timer}}
  end

  @impl true
  def terminate(_reason, %{buffer: buffer, beanstalkd_pid: pid} = _state) do
    Logger.info("Flushing event buffer before shutdown...")
    run(buffer)
  end

  def terminate(reason, _state) do
    Logger.error("Unknown termination - #{inspect(reason)}")
  end

  # attempts to send everything, failed events will be returned to the buffer
  defp run(events) do
    Telemetry.event([:event_stream, :flush], %{}, %{event_count: length(events)})

    events
    |> List.flatten()
    |> Enum.map(fn event ->
      to_send = event |> transform_event()

      Logger.info("Send event lol")
#      # put event in pipe, if failed then log + return the event for retry
#      case ElixirTalk.put(beanstalk_pid, to_send) do
#        {:inserted, _insertion_count} ->
#          :telemetry.execute(
#            [:explorer, :contract_event_stream, :inserted],
#            %{topic: event.topic, contract_address: event.contract_address_hash |> to_string()},
#            %{}
#          )
#
#          nil
#
#        error ->
#          Logger.error("Error sending event to beanstalkd - #{inspect(error)}")
#          event
#      end
    end)
    |> Enum.filter(&(!is_nil(&1)))
  end
end
