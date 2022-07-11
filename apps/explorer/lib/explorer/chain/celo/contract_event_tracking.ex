defmodule Explorer.Chain.Celo.ContractEventTracking do
  @moduledoc """
    Representing an intention to track incoming and historical contract events from a given verified `smart_contract`
  """
  require Logger

  alias __MODULE__
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

    timestamps(null: false, type: :utc_datetime_usec)
  end

  def from_event_topic(smart_contract = %SmartContract{abi: contract_abi}, topic) do
    # create a new contract event tracking from the event that matches the topic
    event_abi =
      contract_abi
      |> Enum.find(fn
        event = %{"type" => "event"} -> SmartContractHelper.event_abi_to_topic_str(event) == topic
        _ -> false
      end)

    case event_abi do
      nil ->
        nil

      valid = %{"name" => name} ->
        ContractEventTracking.create(%{name: name, abi: event_abi, topic: topic, smart_contract: smart_contract})
    end
  end

  def changeset(%__MODULE__{} = event_tracking, attrs) do
    event_tracking
    |> cast(attrs, @attrs)
    |> validate_required(@attrs)
    |> unique_constraint(:celo_wallet_key, name: :celo_wallets_wallet_address_hash_account_address_hash_index)
  end
end
