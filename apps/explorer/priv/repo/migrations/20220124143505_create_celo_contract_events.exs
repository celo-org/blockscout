defmodule Explorer.Repo.Migrations.CreateCeloContractEvents do
  use Ecto.Migration

  def change do
    create table("celo_contract_events") do
      add(:name, :string)
      add(:block_hash, :bytea, null: false)
      add(:transaction_hash, :bytea, null: false)
      add(:contract_address_hash, :bytea, null: false)
      add(:log_index, :integer)
      add(:event_params, :map, default: %{})
    end

    #constraint to prevent duplicate events
    create unique_index(:celo_contract_events, [:transaction_hash, :log_index],
             name: :celo_contract_events_log_index_transaction_hash_index)

    create index(:celo_contract_events, [:name])
    create index(:celo_contract_events, [:transaction_hash])
    create index(:celo_contract_events, [:contract_address_hash])

    execute("CREATE INDEX celo_contract_events_events_params_index ON celo_contract_events USING GIN(event_params)",
            "DROP INDEX celo_contract_events_events_params_index")
  end
end
