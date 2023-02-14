defmodule EventStream.Publisher.Beanstalkd do
  @moduledoc "Publisher implementation for beanstalkd messaging queue."

  alias EventStream.Publisher
  @behaviour Publisher
  require Logger

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    state = %{}

    {:ok, state}
  end

  @impl Publisher
  def publish(event) do
    event
    |> inspect()
    |> then(&Logger.info("Event to send: #{&1}"))
  end
end
