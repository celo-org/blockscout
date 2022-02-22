defmodule Mix.Tasks.GenerateCeloEvents do
  @moduledoc """
    Create event structs from given abis
  """
  use Mix.Task

  @shortdoc "Create event structs for provided abi files"
  def run(_) do
  end

  def parse_abi(path) do
    abi = path
    |> File.read!()
    |> Jason.decode!()

    extract_events(abi)
  end

  def extract_events(abi) do
    require IEx; IEx.pry

    abi
    |> Enum.filter(&( &1["type"] == "event"))
    |> to_event_properties()
  end

  def to_event_properties(event_def = %{"name" => name}) do

    %{
      name: name,
      topic: generate_topic(event_def)
    }
  end

  def generate_topic(event = %{"name" => name}) do
    types = event
    |> Map.get("inputs", [])
    |> Enum.map(&(&1["type"]))
    |> Enum.join(",")

    function_signature = "#{name}(#{types})"

    topic = function_signature
    |> ExKeccak.hash_256()
    |> Base.encode16(case: :lower)

    "0x" <> topic
  end
end
