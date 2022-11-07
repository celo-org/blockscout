defmodule Explorer.Celo.Events.ContractEventStream do
  @moduledoc """
     Accepts events and pushes them to an external queue (beanstalkd)
  """

  use GenServer
  require Logger
  alias Explorer.Chain.CeloContractEvent

  @doc "Accept a list of events and buffer for sending"
  def enqueue(events) do
    GenServer.cast(__MODULE__, {:enqueue, events})

    {:ok, events}
  end

  @doc "Transform celo contract event to expected json format"
  def transform_event(event) do
    event
    |> Explorer.Celo.ContractEvents.EventMap.celo_contract_event_to_concrete_event()
    |> Explorer.Celo.ContractEvents.EventTransformer.to_event_stream_format()

  end

  # callbacks

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @flush_interval_ms 5_000

  @impl true
  def init(buffer) do
    Process.flag(:trap_exit, true)
    timer = Process.send_after(self(), :tick, @flush_interval_ms)

    {:ok, %{buffer: buffer, timer: timer}, {:continue, :connect_to_beanstalk}}
  end


  @impl true
  def handle_continue(:connect_to_beanstalk, state) do
    host = System.get_env("BEANSTALKD_HOST")
    port = "BEANSTALKD_PORT" |> System.get_env() |> Integer.parse()
    tube = "BEANSTALKD_TUBE" |> System.get_env("default")

    pid = connect_beanstalkd(host, port)
    {:using, ^tube} = ElixirTalk.use(pid, tube)

    {:noreply, Map.put(state, :beanstalkd_pid, pid)}
  end

  defp connect_beanstalkd(host, port) do
    {:ok, pid} = ElixirTalk.connect(host, port)
    pid
  end

  @impl true
  def handle_cast({:enqueue, event}, %{buffer: buffer} = state) do
    {:noreply, %{state | buffer: [event | buffer]}}
  end

  @impl true
  def handle_info(:tick, %{buffer: buffer, beanstalkd_pid: pid, timer: timer} = state) do
    Process.cancel_timer(timer)
    failed_events = run(buffer, pid)

    new_timer = Process.send_after(self(), :tick, @flush_interval_ms)

    {:noreply, %{state | buffer: failed_events, timer: new_timer}}
  end

  @impl true
  def terminate(_reason, %{buffer: buffer, beanstalkd_pid: pid} = _state) do
    Logger.info("Flushing event buffer before shutdown...")
    run(buffer, pid)
  end

  # attempts to send everything, failed events will be returned to the buffer
  defp run(events, beanstalk_pid) do
    events
    |> Enum.map(fn event ->
        to_send = event |> transform_event()

        # put event in pipe, if failed then log + return the event for retry
        case ElixirTalk.put(beanstalk_pid, to_send) do
          {:inserted, _insertion_count} -> nil
          error ->
            Logger.error("Error sending event to beanstalkd - #{inspect(error)}")
            event
        end
    end)
    |> Enum.filter(&( !is_nil(&1)))

  end
end