defmodule Explorer.Celo.Events.Transformer do
  @moduledoc "Transform Explorer.Chain.Log + abi to a decoded event instance"

  alias Explorer.Chain.Log
  alias Explorer.Celo.ContractEvents.Common
  alias ABI.FunctionSelector
  require Logger

  # decode json string
  def decode(event_abi, log) when is_binary(event_abi) do
    event_abi
    |> Jason.decode!()
    |> decode(log)
  end

  def decode(event_abi, %{second_topic: second_topic,
    third_topic: third_topic,
    fourth_topic: fourth_topic,
    data: data
  }) when is_map(event_abi) do
    # extract necessary data from abi selector
    %{input_names: inputs, inputs_indexed: indexed, types: types} = FunctionSelector.parse_specification_item(event_abi)

    event_params = [inputs, indexed, types]
             |> Enum.zip()

    # decode indexed parameters directly from topics
    indexed_params =
      event_params
      |> Enum.filter(fn {_name, indexed, _type} -> indexed == true end)
      |> Enum.zip([second_topic, third_topic, fourth_topic])
      |> Enum.into(%{}, fn {{name, _indexed, type}, topic} -> {String.to_atom(name), Common.decode_event_topic(topic, type) } end)

    # decode unindexed parameters from the log data body via their declaration order within the event abi
    unindexed_param_specs =
      event_params
      |> Enum.filter(fn {_, indexed, _} -> indexed == false end)

    unindexed_param_values =
      unindexed_param_specs
      |> Enum.map(fn {_name,_indexed, type} -> type end)
      |> then(&(Common.decode_event_data(data, &1)))

    unindexed_params =
      [unindexed_param_specs, unindexed_param_values]
      |> Enum.zip()
      |> Enum.into(%{}, fn {{name, _i, _type}, value} -> {String.to_atom(name), value} end)

    # reconcile indexed and unindexed
    unindexed_params |> Map.merge(indexed_params)
  end

  def decode16!(nil), do: nil

  def decode16!(value) do
    value
    |> String.trim_leading("0x")
    |> Base.decode16!(case: :lower)
  end
end