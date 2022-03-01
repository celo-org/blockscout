defmodule Mix.Tasks.GenerateCeloEvents do
  @moduledoc """
    Create event structs from given abis
  """
  use Mix.Task

  @abi_path "priv/contracts_abi/celo/"
  @shortdoc "Create event structs for provided abi files"

  def run(args) do
    {options, _, _} = OptionParser.parse(args, strict: [path: :string])
    path = options[:path] || @abi_path

    contract_name_to_event_defs = Path.wildcard(path <> "/*.json")
    |> Enum.into(%{}, fn path ->
      {Path.basename(path, ".json") |> String.capitalize() , parse_abi(path)}
    end)

    require IEx; IEx.pry

  end

  def parse_abi(path) do
    abi = path
    |> File.read!()
    |> Jason.decode!()

    extract_events(abi)
  end

  def extract_events(abi) do
    abi
    |> Enum.filter(&( &1["type"] == "event"))
    |> Enum.map(&to_event_properties/1)
  end

  def to_event_properties(event_def = %{"name" => name}) do
    #create tuples in the format expected by Explorer.Celo.ContractEvents.Base.event_param/3
    params = event_def
    |> Map.get("inputs", [])
    |> Enum.map(fn %{"indexed" => indexed, "name" => name, "type" => type} ->
      indexed = if indexed, do: :indexed, else: :unindexed

      name = name
      |> Macro.underscore()
      |> String.to_atom()

      type = extract_type(type)

      {name, type, indexed}
    end)

    %{
      name: name,
      topic: generate_topic(event_def),
      params: params
    }
  end

  #convert to format expected by ABI library for decoding blockchain primitive types
  def extract_type("uint256"), do: {:uint, 256}
  def extract_type("address"), do: :address
  def extract_type("bytes"), do: :bytes
  def extract_type("bytes32"), do: {:bytes, 32}
  def extract_type("string"), do: :string
  def extract_type("bytes32[]"), do: {:array, {:bytes, 32}}
  def extract_type("uint256[]"), do: {:array, {:uint, 256}}
  def extract_type("bytes4"), do: {:bytes, 4}


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

  def generate_event_struct(module, event_data) do
    EEx.eval_file("lib/mix/tasks/event_struct.eex", module: module, event: event_data)
  end
end
