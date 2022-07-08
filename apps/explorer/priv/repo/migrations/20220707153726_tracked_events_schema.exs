defmodule Explorer.Repo.Migrations.TrackedEventsSchema do
  use Ecto.Migration

  def change do
    create table(:clabs_contract_event_trackings) do
      add(:smart_contract_id, references(:smart_contracts), null: false)
      add(:transaction_hash, references(:transactions, column: "hash", type: "bytea"), null: false)

      add(:abi, :jsonb, null: false)
      add(:topic, :string, null: false)
      add(:name, :string, null: false)

      add(:backfilled, :boolean, null: false, default: false)
      add(:enabled, :boolean, null: false, default: false)

      timestamps()
    end

    create(index(:clabs_contract_event_trackings, :topic))
    create(index(:clabs_contract_event_trackings, :backfilled))

    create table(:clabs_tracked_contract_events, primary_key: false) do
      add(:block_number, :integer, primary_key: true, null: false)
      add(:log_index, :integer, primary_key: true, null: false)

      add(:contract_event_tracking_id, references(:clabs_contract_event_tracking), null: false)
      add(:contract_address_hash, references(:smart_contracts, :address_hash, type: :bytea), null: false)

      add(:topic, :string, null: false)
      add(:name, :string, null: false)
      add(:params, :jsonb)

      add(:bq_rep_id, :bigserial)

      timestamps()
    end

    create(index(:clabs_tracked_contract_events, :block_number))
    create(index(:clabs_tracked_contract_events, :updated_at))
    # Intentionally not adding a GIN index to params as in celo_contract_events as generic contracts aren't
    # integral to the celo protocol. When necessary partial indices over contract addresses can be added for the same
    # result.
  end
end
