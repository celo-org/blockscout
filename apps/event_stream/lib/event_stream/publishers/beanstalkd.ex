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
    # charlist required instead of string due to erlang lib quirk
    host = Keyword.fetch!(opts, :host) |> to_charlist()
    tube = Keyword.get(opts, :tube, "default")
    port = Keyword.get(opts, :port, 11300)

    state = %{beanstalk: %{
      host: host,
      tube: tube,
      port: port
    }}

    {:ok, state, {:continue, :connect_beanstalk}}
  end

  @impl true
  def handle_continue(:connect_beanstalk, state = %{beanstalk: %{host: host, port: port, tube: tube}}) do
    Logger.info("Connecting to beanstalkd on #{host |> to_string()}:#{port |> to_string()}...")
    {:ok, pid} = ElixirTalk.connect(host, port)

    Logger.info("Connected, using tube #{tube}")
    {:using, ^tube} = ElixirTalk.use(pid, tube)

    {:noreply, put_in(state, [:beanstalk, :pid], pid)}
  end

  @impl Publisher
  def publish(event) do
    try do
      GenServer.call(__MODULE__, {:publish, event})
      :ok
    rescue
      error ->
        Logger.error("Error sending event:#{inspect(event)} error:#{inspect(error)}")
        {:failed, event}
    end
  end

  @impl true
  def handle_call({:publish, event}, _sender, state = %{beanstalk: %{pid: pid}}) do
    {:inserted, 1} = beanstalk_publish(pid, event)

    {:reply, :ok, state}
  end

  defp beanstalk_publish(beanstalk_pid, event) do
    ElixirTalk.put(beanstalk_pid, event)
  end
end
