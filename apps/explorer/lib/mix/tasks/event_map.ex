defmodule Mix.Tasks.EventMap do
  @moduledoc "Build a map of celo contract events to topics"

  use Mix.Task

  alias Explorer.Celo.ContractEvents.EventTransformer

  @template """
  # This file is auto generated, changes will be lost upon regeneration

  defmodule Explorer.Celo.ContractEvents.EventMap do
    @moduledoc "Map event names and event topics to concrete contract event structs"

    alias Explorer.Celo.ContractEvents.EventTransformer

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

    def celo_contract_event_to_concrete_event(events) when is_list(events) do
      events
      |> Enum.map(fn params = %{name: name} ->
        case event_for_name(name) do
          nil ->
            nil

          event ->
            event
            |> struct!()
            |> EventTransformer.from_celo_contract_event(params)
        end
      end)
      |> Enum.reject(&is_nil/1)
    end

    @topic_to_event %{
    <%= for module <- @modules do %>  "<%= module.topic %>" =>
      <%= module %>,
    <% end %>}

    @name_to_event %{
    <%= for module <- @modules do %>  "<%= module.name %>" =>
      <%= module %>,
    <% end %>}

    def event_for_topic(topic), do: Map.get(@topic_to_event, topic)
    def event_for_name(name), do: Map.get(@name_to_event, name)

  end

  """

  @path "lib/explorer/celo/events/contract_events/event_map.ex"

  @shortdoc "Creates a module mapping topics to event names and vice versa"
  def run(_) do
    modules = get_events()
    event_map = EEx.eval_string(@template, assigns: [modules: modules])

    IO.puts(event_map)
    _ = File.rm(@path)
    File.write(@path, event_map)
  end

  defp get_events do
    :impls
    |> EventTransformer.__protocol__()
    |> then(fn
      {:consolidated, modules} ->
        modules

      _ ->
        Protocol.extract_impls(
          Explorer.Celo.ContractEvents.EventTransformer,
          [:code.lib_dir(:explorer, :ebin)]
        )
    end)
  end
end
