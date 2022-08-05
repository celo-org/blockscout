defmodule Explorer.Celo.Events.Transformer do
  @moduledoc "Transform Explorer.Chain.Log + Event ABI to a human readable map of parameters"

  alias Explorer.Chain.Log
  alias Explorer.Celo.ContractEvents.Common
  alias ABI.FunctionSelector
  require Logger

  def decode(%FunctionSelector{input_names: inputs, inputs_indexed: indexed, types: types}, %{
        second_topic: second_topic,
        third_topic: third_topic,
        fourth_topic: fourth_topic,
        data: data
      }) do
    event_params =
      [inputs, indexed, types]
      |> Enum.zip()

    event_params
    |> decode_indexed([second_topic, third_topic, fourth_topic])
    |> Map.merge(decode_unindexed(event_params, data))
  end

  # decode json string
  def decode(event_abi, log) when is_binary(event_abi) do
    event_abi
    |> Jason.decode!()
    |> decode(log)
  end

  # convert abi map into ABI.FunctionSelector
  def decode(event_abi, log) when is_map(event_abi) do
    event_abi
    |> FunctionSelector.parse_specification_item()
    |> decode(log)
  end

  # relevant_topics are the second to fourth topics - the first topic is always the event identifier
  defp decode_indexed(event_params, relevant_topics) do
      event_params
      |> Enum.filter(fn {_name, indexed, _type} -> indexed == true end)
      |> Enum.zip(relevant_topics)
      |> Enum.into(%{}, fn {{name, _indexed, type}, topic} ->
        {String.to_atom(name), Common.decode_event_topic(topic, type)}
      end)
  end

  defp decode_unindexed(event_params, data) do
    unindexed_param_specs =
      event_params
      |> Enum.filter(fn {_, indexed, _} -> indexed == false end)

    # get unindexed param values in canonical order
    unindexed_param_values =
      unindexed_param_specs
      |> Enum.map(fn {_name, _indexed, type} -> type end)
      |> then(&Common.decode_event_data(data, &1))

    # reconcile values with parameter name
    [unindexed_param_specs, unindexed_param_values]
    |> Enum.zip()
    |> Enum.into(%{}, fn {{name, _i, _type}, value} -> {String.to_atom(name), value} end)
  end

  defp decode16!(nil), do: nil

  defp decode16!(value) do
    value
    |> String.trim_leading("0x")
    |> Base.decode16!(case: :lower)
  end
end
