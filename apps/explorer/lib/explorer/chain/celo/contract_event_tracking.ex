defmodule Explorer.Chain.Celo.ContractEventTracking do
  @moduledoc """
    Representing an intention to track incoming and historical contract events from a given verified `smart_contract`
  """
  require Logger

  alias __MODULE__
  alias Explorer.Chain.Celo.TrackedContractEvent
  alias Explorer.Chain.{Hash, SmartContract}
  alias Explorer.Chain.Hash.Address
  alias Explorer.Repo
  alias Explorer.SmartContract.Helper, as: SmartContractHelper

  use Explorer.Schema
  import Ecto.Query

  @type t :: %__MODULE__{
               abi: map(),
               name: String.t(),
               topic: String.t(),
               backfilled: boolean(),
               enabled: boolean(),
               smart_contract_id: non_neg_integer()
             }

  @attrs ~w(
          abi name topic smart_contract_id
        )a

  schema "clabs_contract_event_trackings" do
    field(:abi, :map)
    field(:name, :string)
    field(:topic, :string)
    field(:backfilled, :boolean)
    field(:enabled, :boolean)

    belongs_to(:smart_contract, SmartContract)
    has_one(:address, through: [:smart_contract, :address_hash])
    has_many(:tracked_contract_events, TrackedContractEvent)

    timestamps(null: false, type: :utc_datetime_usec)
  end

  def from_event_topic(smart_contract, topic) do
    find_function = fn
        event = %{"type" => "event"} -> SmartContractHelper.event_abi_to_topic_str(event) == topic
        _ -> false
      end

    build_tracking(smart_contract, find_function)
  end


  def from_event_name(smart_contract, name) do
    find_function = fn
     %{"type" => "event", "name" => ^name} -> true
      _ -> false
    end

    build_tracking(smart_contract, find_function)
  end

  defp build_tracking(%SmartContract{abi: contract_abi} = smart_contract, find_function) do
    event_abi =
      contract_abi
      |> Enum.find(find_function)

    case event_abi do
      nil ->
        nil

      %{"name" => name} ->
        topic = SmartContractHelper.event_abi_to_topic_str(event_abi)

        %ContractEventTracking{}
        |> changeset( %{name: name, abi: event_abi, topic: topic, smart_contract: smart_contract})
    end
  end

  def changeset(%__MODULE__{} = event_tracking, %{smart_contract_id: _scid} = attrs) do
    event_tracking
    |> cast(attrs, @attrs)
    |> validate_required(@attrs)
  end

  def changeset(%__MODULE__{} = event_tracking, %{smart_contract: sc} = attrs) do
    attrs
    |> Map.put(:smart_contract_id, sc.id)
    |> then(&(changeset(event_tracking, &1)))
  end
end
