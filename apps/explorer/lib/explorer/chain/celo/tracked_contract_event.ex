defmodule Explorer.Chain.Celo.TrackedContractEvent do
  @moduledoc """
    Representing a contract event emitted from a verified `smart_contract` and with a matching `contract_event_tracking` entry
  """
  require Logger

  alias __MODULE__
  alias Explorer.Chain.Celo.ContractEventTracking
  alias Explorer.Chain.{Hash, SmartContract, Transaction}
  alias Explorer.Chain.Hash.Address
  alias Explorer.Repo
  alias Explorer.SmartContract.Helper, as: SmartContractHelper

  use Explorer.Schema
  import Ecto.Query

  @type t :: %__MODULE__{
               block_number: integer(),
               log_index: integer(),
               name: String.t(),
               topic: String.t(),
               params: map(),
               transaction_hash: Address.Full.t(),
               contract_address_hash: Address.Full.t(),
               contract_event_tracking_id: non_neg_integer()
             }

  @attrs ~w(
          block_number log_index name topic params transaction_hash contract_address_hash contract_event_tracking_id
        )a

  @primary_key false
  schema "clabs_tracked_contract_event" do
    field(:block_number, :integer, primary_key: true)
    field(:log_index, :integer, primary_key: true)

    field(:topic, :string)
    field(:name, :string)
    field(:params, :map)

    belongs_to(:contract_event_tracking, ContractEventTracking)
    belongs_to(:smart_contract, SmartContract, foreign_key: :contract_address_hash, references: :address_hash)
    belongs_to(:transaction, Transaction, foreign_key: :transaction_hash, references: :hash)

    has_one(:address, through: [:smart_contract, :address_hash])

    timestamps(null: false, type: :utc_datetime_usec)
  end


end