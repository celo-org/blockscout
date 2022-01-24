defmodule Explorer.Chain.CeloContractEvent do
  @moduledoc """
    Representing an event emitted from a Celo core contract.
  """
  require Logger

  use Explorer.Schema

  alias Explorer.Chain.Hash.Address

  @attrs ~w( name contract_address_hash transaction_hash block_hash index params)a

  schema "celo_contract_events" do
    field(:name, :string)
    field(:params, :map)
    field(:log_index, :integer)
    field(:contract_address_hash, Address)
    field(:transaction_hash, Address)
    field(:block_hash, Address)

    timestamps(null: false, type: :utc_datetime_usec)
  end

  def changeset(%__MODULE__{} = item, attrs) do
    item
    |> cast(attrs, @attrs)
    |> validate_required(@attrs)
    |> unique_constraint(:celo_contract_events_duplicate_event, name: :celo_contract_events_log_transaction_index)
  end
end
