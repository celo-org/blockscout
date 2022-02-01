defmodule Explorer.Celo.ContractEvents.EventMap do
  @moduledoc "Map event names and event topics to concrete contract event structs"
  alias Explorer.Celo.ContractEvents.EventTransformer

  def event_for_topic(topic), do: filter_events(fn module -> module.topic == topic end)

  def event_for_name(name), do: filter_events(fn module -> module.name == name end)

  defp filter_events(filter) do
    EventTransformer.__protocol__(:impls)
    |> then(fn
      {:consolidated, modules} ->
        modules

      _ ->
        Protocol.extract_impls(
          Explorer.Celo.ContractEvents.EventTransformer,
          :code.lib_dir(:explorer)
        )
    end)
    |> Enum.find(filter)
  end

  def rpc_to_event_params(logs) when is_list(logs) do
    logs
    |> Enum.map(fn params = %{first_topic: event_topic} ->
      case event_for_topic(event_topic) do
        nil ->
          nil

        event ->
          event
          |> struct!()
          |> EventTransformer.from_params(params)
          |> EventTransformer.to_celo_contract_event_params()
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
end
