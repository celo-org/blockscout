defmodule Explorer.Celo.ContractEvents.EventMap do
  alias Explorer.Celo.ContractEvents.EventTransformer

  @topics_to_structs EventTransformer.__protocol__(:impls)
                     |> elem(1)
                     |> Enum.map(fn module ->  {module.topic, struct(module)} end)
                     |> Map.new()

  @names_to_structs EventTransformer.__protocol__(:impls)
                    |> elem(1)
                    |> Enum.map(fn module ->  {module.name, struct(module)} end)
                    |> Map.new()


  def event_for_topic(topic), do: Map.get(@topics_to_structs,topic)

  def event_for_name(name), do: Map.get(@names_to_structs,name)



end
