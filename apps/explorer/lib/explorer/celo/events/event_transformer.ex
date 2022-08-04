defmodule Explorer.Celo.Events.Transformer do
  @moduledoc "Transform Explorer.Chain.Log + abi to a decoded event instance"

  alias Explorer.Chain.Log

  # decode json string
  def decode(event_abi, log) when is_binary(event_abi) do
    event_abi
    |> Jason.decode!()
    |> decode(log)
  end

  #
  def decode(event_abi, log) when is_map(event_abi) do
    %{}
  end
end