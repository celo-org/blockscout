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
         {:ok, tracking_changesets} <- get_changesets(contract, options[:topics], options[:event_names], options[:all]) do

      tracking_changesets
      |> Enum.each(fn changeset ->
        case Repo.insert(changeset) do
          {:ok, cet = %ContractEventTracking{}} ->
            Logger.info("Tracking new instances of #{cet.topic} (#{cet.name}) on contract #{contract.address |> to_string()} (#{contract.name})")
          {:error, %Ecto.Changeset{errors: errors, changes: %{name: name, topic: topic}}} ->
            Logger.error "Errors found with event #{topic} (#{name}) - #{errors}"
        end
      end)
      require IEx; IEx.pry
    else
      {:error, reason} ->
        raise "Failure: #{reason}"
    end
  end

  defp get_changesets(contract, _topics, _names, true) do
    topics = get_all_event_topics(contract)
    get_changesets(contract, topics, nil, nil)
  end

  defp get_changesets(contract, _topics, names, _all) when is_binary(names) do
    names = names |> String.split(",")

    trackings = names
    |> Enum.map(fn name ->
      case ContractEventTracking.from_event_name(contract, name) do
        cet = %Ecto.Changeset{valid?: true} ->
          cet
        %Ecto.Changeset{valid?: false, errors: errors} ->
          raise "Errors found with event name #{name} - #{errors}"
        nil ->
          raise "Event name #{name} not found in contract #{contract.name}"
      end
    end)

    {:ok, trackings}
  end

  defp get_changesets(contract, topics, _names, _all) when is_list(topics) do
    trackings = topics
      |> Enum.map(fn topic ->
      case ContractEventTracking.from_event_topic(contract, topic) do
        cet = %Ecto.Changeset{valid?: true} ->
          cet
        %Ecto.Changeset{valid?: false, errors: errors} ->
          raise "Errors found with event name #{topic} - #{errors}"
        nil ->
          raise "Event topic #{topic} not found in contract #{contract.name}"
      end
    end)

    {:ok, trackings}
  end

  defp get_changesets(contract, topics, _names, _all) when is_binary(topics) do
    topics = topics |> String.split(",")
    get_changesets(contract, topics, nil, nil)
  end

  defp get_all_event_topics(%SmartContract{abi: abi}) do
    abi
    |> Enum.filter(fn
      %{"type" => "event"} -> true
      _ -> false
    end)
    |> Enum.map(fn event_abi ->
      Explorer.SmartContract.Helper.event_abi_to_topic_str(event_abi)
    end)
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
