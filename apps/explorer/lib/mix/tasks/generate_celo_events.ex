defmodule Mix.Tasks.GenerateCeloEvents do
  @moduledoc """
    Create event structs from given abis
  """
  use Mix.Task
  require Logger

  @abi_path "priv/contracts_abi/celo/"
  @destination_path "lib/explorer/celo/events/contract_events"
  @shortdoc "Create event structs for provided abi files"

  def run(args) do
    {options, args, _} = OptionParser.parse(args, strict: [path: :string, destination: :string, only: :boolean])
    path = options[:path] || @abi_path
    destination = options[:destination] || @destination_path

    contract_name_to_event_defs =
      Path.wildcard(path <> "/*.json")
      |> Enum.into(%{}, fn path ->
        {Path.basename(path, ".json") |> String.capitalize(), parse_abi(path)}
      end)
      |> extract_common_events()

    # extract only provided event names if `only` flag given in cli
    events_to_generate =
      if options[:only] do
        contract_name_to_event_defs
        |> Enum.map(fn {k, v} ->
          {k, v |> Enum.filter(&Enum.member?(args, &1.name))}
        end)
        |> Enum.filter(fn
          {_, []} -> false
          _ -> true
        end)
        |> Enum.into(%{})
      else
        contract_name_to_event_defs
      end

    events_to_generate
    |> Enum.each(fn {contract_name, event_defs} ->
      write_events(destination, contract_name, event_defs)
    end)
  end

  def write_events(destination, names, events) when is_list(names) do
    write_events(destination, names, "Common", events)
  end

  def write_events(destination, name, events) do
    write_events(destination, name, name, events)
  end

  def write_events(destination, name, module_name, events) do
    dir = Path.join(destination, String.downcase(module_name))

    case File.mkdir(dir) do
      :ok -> nil
      {:error, :eexist} -> nil
      e -> raise("Error creating dir #{dir}", e)
    end

    events
    |> Enum.each(fn event_def ->
      module = "#{module_name}.#{event_def.name}Event"
      filename = Macro.underscore(event_def.name) <> "_event.ex"
      event_content = generate_event_struct(module, event_def, contract_name: name)

      event_path = Path.join(dir, filename)

      case File.write(event_path, event_content) do
        :ok -> Logger.info("Generated #{event_path}")
        e -> raise("Error creating #{event_path}", e)
      end
    end)
  end

  def parse_abi(path) do
    abi =
      path
      |> File.read!()
      |> Jason.decode!()

    extract_events(abi)
  end

  def extract_events(abi) do
    abi
    |> Enum.filter(&(&1["type"] == "event"))
    |> Enum.map(&to_event_properties/1)
  end

  def extract_common_events(contract_name_to_event_defs = %{}) do
    #create a map of all events grouped by topic
    events_by_topic = contract_name_to_event_defs
    |> Enum.reduce(%{}, fn {name, defs}, acc ->
      defs |> Enum.reduce(acc, fn event, map ->
        case Map.get(map, event.topic)  do
          nil -> Map.put(map, event.topic, [{name, event}])
          e -> Map.put(map, event.topic, [{name, event} | e])
        end
      end)
    end)

    #get events with more than one entry per topic
    duplicates = events_by_topic
                 |> Enum.filter(fn {_topic, events} -> Enum.count(events) > 1 end)

    duplicate_topics = duplicates |> Enum.map(fn {topic, _events} -> topic end) |> MapSet.new()


    #remove duplicates from existing contract names
    deduped_contract_map = contract_name_to_event_defs
    |> Enum.map(fn {name, events} ->
      {name, Enum.reject(events, &(MapSet.member?(duplicate_topics, &1.topic)))}
    end)

    #create a "common" module for events with shared references
    common_events = duplicates
    |> Enum.map(fn {_topic, events} ->
      contracts_with_event = Enum.reduce(events, fn {name, _defs} -> name end)
      {_, event_def} = List.first(events)
      {contracts_with_event, event_def}
    end)

    Map.put(deduped_contract_map, "Common", common_events)
  end

  def to_event_properties(event_def = %{"name" => name}) do
    # create tuples in the format expected by Explorer.Celo.ContractEvents.Base.event_param/3
    params =
      event_def
      |> Map.get("inputs", [])
      |> Enum.map(fn %{"indexed" => indexed, "name" => name, "type" => type} ->
        indexed = if indexed, do: :indexed, else: :unindexed

        name =
          name
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

  # convert to format expected by ABI library for decoding blockchain primitive types
  def extract_type("uint256"), do: {:uint, 256}
  def extract_type("address"), do: :address

  def extract_type("bytes"), do: :bytes
  def extract_type("bytes32"), do: {:bytes, 32}
  def extract_type("string"), do: :string
  def extract_type("bytes32[]"), do: {:array, {:bytes, 32}}
  def extract_type("uint256[]"), do: {:array, {:uint, 256}}
  def extract_type("bytes4"), do: {:bytes, 4}

  def generate_topic(event = %{"name" => name}) do
    types =
      event
      |> Map.get("inputs", [])
      |> Enum.map(& &1["type"])
      |> Enum.join(",")

    function_signature = "#{name}(#{types})"

    topic =
      function_signature
      |> ExKeccak.hash_256()
      |> Base.encode16(case: :lower)

    "0x" <> topic
  end

  def generate_event_struct(module, event_data, opts \\ []) do
    contract_name = Keyword.get(opts, :contract_name) || "unknown"
    EEx.eval_file("lib/mix/tasks/event_struct.eex", module: module, event: event_data, contract: contract_name)
  end
end
