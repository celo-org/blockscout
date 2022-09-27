defmodule Mix.Tasks.ListEvents do
  @shortdoc "List all events on a given contract"

  require Logger
  use Mix.Task
  alias Explorer.{Chain, Repo}
  alias Explorer.SmartContract.Helper, as: SmartContractHelper
  alias Mix.Task, as: MixTask

  import Ecto.Query
  import Mix.Tasks.TrackEvent, only: [get_verified_contract: 1]

  def run(args) do
    {options, _args, invalid} =
      OptionParser.parse(args, strict: [contract_address: :string])

    validate_preconditions(invalid)

    # start ecto repo
    MixTask.run("app.start")

    with {:ok, contract} <- get_verified_contract(options[:contract_address]),
                is_proxy <- Chain.proxy_contract?(contract.address_hash, contract.abi) do

      events = if is_proxy do
        implementation_contract = get_implementation_contract(contract)
          filter_events(contract.abi) ++ filter_events(implementation_contract.abi)
        else
          filter_events(contract.abi)
      end

      already_tracked_events = contract |> get_event_trackings()

      list_events(contract, events, already_tracked_events)
    else
      {:error, reason} ->
        raise "Failure: #{reason}"
    end
  end

  defp validate_preconditions(invalid) do
    unless invalid == [] do
      raise "Invalid options types passed: #{invalid}"
    end

    unless System.get_env("DATABASE_URL") do
      raise "No database connection provided - set DATABASE_URL env variable"
    end
  end

  def get_event_trackings(contract) do
    from( cet in Explorer.Chain.Celo.ContractEventTracking, where: cet.smart_contract_id == ^contract.id)
    |> Repo.all()
  end

  def filter_events(abi) do
    abi |> Enum.filter(&(&1["type"] == "event"))
  end

  def get_implementation_contract(%{address_hash: address_hash, abi: abi}) do
    implementation_address = Chain.get_implementation_address_hash(address_hash, abi)
    {:ok, contract } = get_verified_contract(implementation_address)
    contract
  end

  def list_events(contract, events, already_tracked_events) do
    IO.puts("")
    IO.puts("##  #{contract.address_hash |> to_string()} (#{contract.name}) Events")
    IO.puts("")
    IO.puts("  event name - event topic - already tracked")
    IO.puts("")

    tracked_topics = already_tracked_events |> Enum.map(& &1.topic) |> MapSet.new()

    events
    |> Enum.each(fn event ->
      name = event["name"] || "(anonymous)"
      topic = SmartContractHelper.event_abi_to_topic_str(event)
      tracked = MapSet.member?(tracked_topics, topic)

      IO.puts("  #{name} - #{topic} - #{if tracked do "tracked" else "untracked" end} ")

    end)
  end
end
