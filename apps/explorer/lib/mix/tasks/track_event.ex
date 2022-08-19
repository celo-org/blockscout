defmodule Mix.Tasks.TrackEvent do
  @moduledoc """
    Track events of verified contracts
  """
  use Mix.Task
  require Logger

  alias Explorer.Repo
  alias Explorer.Chain.SmartContract
  alias Explorer.Chain.Celo.ContractEventTracking
  import Ecto.Query

  def run(args) do
    {options, args, invalid} =
      OptionParser.parse(args, strict: [contract_address: :string, topics: :string, event_names: :string, all: :boolean] )

    validate_preconditions(invalid)

    #start ecto repo
    Mix.Task.run "app.start"

    with {:ok, contract} <- get_verified_contract(options[:contract_address]),
         {:ok, filtered_events} <- extract_abis_to_track(contract, options[:topics], options[:event_names], options[:all]) do

      create_tracking_records(contract, filtered_events)
    else
      {:error, reason} ->
        raise "Failure: #{reason}"
    end
  end

  defp extract_abis_to_track(contract, _topics, _names, true), do: {:ok, events}
  defp extract_abis_to_track(contract, _topics, names, _all) when is_binary(names) do
    names = names |> String.split(",")

    names
    |> Enum.map(fn name ->
      ContractEventTracking.from_event_name(contract, name)
    end)
    matching_events =
      events
    |> Enum.reduce(%{}, fn event, acc ->
      case Enum.find(names, &( &1 == event["name"])) do
        found_name -> Map.put(acc, found_name, event)
        nil -> acc
      end
    end)

    #check that all specified names were found
    all_keys_found  = Enum.sort(names) == Enum.sort(Map.keys(matching_events))

    if all_keys_found do
      {:ok, Map.values(matching_events)}
    else
      found_names = Map.keys(matching_events)
      missing_names =
        names
        |> MapSet.new()
        |> MapSet.difference(MapSet.new(found_names))
        |> MapSet.to_list()

      {:error, "Specified event names not found in contract - #{missing_names |> Enum.join(", ")}"}
    end
  end

  defp extract_abis_to_track(events, topics, _names, _all) when is_binary(topics) do
    topics = topics |> String.split(",")

  end
  defp create_tracking_records(contract, events) do
    require IEx; IEx.pry
  end

  defp extract_event_abis(%SmartContract{name: name, abi: abi}) do
    events =
      abi
      |> Enum.filter(fn
        %{"type" => "event"} -> true
        _ -> false
      end)

    case events do
      [] ->
        {:error, "Contract at given address (#{name}) has no events defined in ABI"}

      _ ->
        {:ok, events}
    end
  end

  defp validate_preconditions(invalid) do
    unless invalid == [] do
      raise "Invalid options types passed: #{invalid}"
    end

    unless System.get_env( "DATABASE_URL" ) do
      raise "No database connection provided - set DATABASE_URL env variable"
    end
  end

  def get_verified_contract(address_string) do
    case Explorer.Chain.Hash.Address.cast(address_string) do
      :error ->
        {:error, "Invalid format for address hash"}

      {:ok, address} ->
        contract = from(
          sm in SmartContract,
          where: sm.address_hash == ^address)
        |> Repo.one()

        case contract do
          sm = %SmartContract{} ->
            {:ok, sm}
          nil ->
            {:error, "No verified contract found at address #{address_string}"}
        end
    end
  end
end
