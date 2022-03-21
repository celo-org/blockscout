defmodule Explorer.Repo.Migrations.AddCeloContracts do
  use Ecto.Migration
  alias Explorer.Celo.ContractEvents.Registry.RegistryUpdatedEvent

  def up do
    create table(:celo_core_contracts) do
      add(:address_hash, :bytea, null: false, primary_key: true)
      add(:name, :string, null: false)
      add(:block_number, :integer)
      add(:log_index, :integer)

      timestamps()
    end

    flush()

    # get all core contracts (registry entries)
    core_contracts = RegistryUpdatedEvent.core_contracts()
    |> repo().all()
    |> Explorer.Celo.ContractEvents.EventMap.rpc_to_event_params()
    |> Enum.map(fn e ->
      %{name: e.params.identifier, address_hash: e.params.addr, block_number: e.block_number, log_index: e.log_index}
    end)
    |> then(&( [ %{name: "Registry", address_hash: "\\x000000000000000000000000000000000000ce10", block_number: 1, log_index: 0} | &1 ] ))
    |> Enum.map(fn e ->
      e
      |> Map.put(:inserted_at, Timex.now())
      |> Map.put(:updated_at, Timex.now())
    end)

    # insert into new table
    contract_length = length(core_contracts)
    {^contract_length, _} = repo().insert_all("celo_core_contracts", core_contracts)
  end

  def down do
    drop(table(:celo_core_contracts))
  end
end
