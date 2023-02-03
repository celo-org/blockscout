defmodule BlockScoutWeb.Celo.MetricsCron do
  @moduledoc "Periodic metrics tasks"

  require Logger
  use GenServer

  alias BlockScoutWeb.Celo.MetricsCron.TaskSupervisor

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_) do
    repeat()
    {:ok, %{running_operations: []}}
  end

  defp config(key) do
    Application.get_env(:block_scout_web, __MODULE__, [])[key]
  end

  defp repeat do
    interval = config(:metrics_cron_interval_seconds)
    Process.send_after(self(), :import_and_reschedule, :timer.seconds(interval))
  end

  @metric_operations [
    :dummy_log
  ]

  @impl true
  def handle_info(:import_and_reschedule, %{running_operations: running} = state) do
    unless running == [] do
      Logger.info("MetricsCron scheduled, tasks still running: #{Enum.join(running, ",")}")
    end

    running_operations =
      @metric_operations
      |> Enum.filter(&(!Enum.member?(running, &1)))
      |> Enum.map(fn operation ->
        Task.Supervisor.async_nolink(TaskSupervisor, fn ->
          apply(__MODULE__, operation, [])
          {:completed, operation}
        end)

        operation
      end)

    repeat()

    {:noreply, %{state | running_operations: running_operations}}
  end

  @impl true
  def handle_info({_task_ref, {:completed, operation}}, %{running_operations: ops} = state) do
    {:noreply, %{state | running_operations: List.delete(ops, operation)}}
  end

  @impl true
  def handle_info({:DOWN, _, _, _, :normal}, state), do: {:noreply, state}

  @impl true
  def handle_info({:DOWN, _, _, _, failure_message}, state) do
    Logger.error("MetricsCron task received an error: #{failure_message |> inspect()}")
    {:noreply, state}
  end

  def dummy_log do
    Logger.info("Hello I have been invoked")
  end
end