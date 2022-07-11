defmodule Explorer.Chain.Celo.ContractEventTracking do
  @moduledoc """
    Representing an intention to track incoming and historical contract events from a given verified `smart_contract`
  """
  require Logger

  alias __MODULE__
  alias Explorer.Chain.Hash
  alias Explorer.Chain.Hash.Address
  alias Explorer.Repo

  use Explorer.Schema
  import Ecto.Query

  @type t :: %__MODULE__{
               abi: map(),
               name: String.t(),
               topic: String.t(),
               backfilled: boolean(),
               enabled: boolean(),
               transaction_hash: Hash.Full.t(),
               smart_contract_id: non_neg_integer()
             }

  schema "clabs_contract_event_trackings" do
    field(:abi, :map)
    field(:name, :string)
    field(:topic, :string)
    field(:backfilled, :boolean)
    field(:enabled, :boolean)

    belongs_to(:smart_contract, SmartContract)
    belongs_to(:transaction, Transactions, foreign_key: :transaction_hash, references: :hash, type: Hash.Address)

    has_one :address, through: [:smart_contract, :address_hash]

    timestamps(null: false, type: :utc_datetime_usec)
  end
end