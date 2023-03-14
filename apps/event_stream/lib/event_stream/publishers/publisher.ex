defmodule EventStream.Publisher do
  @moduledoc "Representing an instance of where to publish"

  @doc """
  Fetch a contract address for a given name
  """
  @callback publish(String.t()) :: :ok | {:failed, String.t()}

  @callback live() :: boolean

  # credo:disable-for-next-line
  @implementation Application.compile_env!(:event_stream, __MODULE__)

  defdelegate publish(contract_name), to: @implementation

  def connected? do
    @implementation.live()
  end
end
