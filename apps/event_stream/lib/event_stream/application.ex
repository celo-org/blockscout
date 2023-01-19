defmodule EventStream.Application do
  @moduledoc """
  This is the Application module for EventStream.
  """

  use Application

  alias EventStream.Celo.Events.ContractEventStream

  @impl Application
  def start(_type, _args) do
    # Children to start in all environments
    base_children = []

    children = base_children ++ configurable_children()

    opts = [strategy: :one_for_one, name: EventStream.Supervisor, max_restarts: 1_000]

    Supervisor.start_link(children, opts)
  end

  defp configurable_children do
    [
      configure(ContractEventStream)
    ]
    |> List.flatten()
  end

  defp should_start?(process) do
    Application.get_env(:event_stream, process, [])[:enabled] == true
  end

  defp configure(process) do
    if should_start?(process) do
      process
    else
      []
    end
  end
end
