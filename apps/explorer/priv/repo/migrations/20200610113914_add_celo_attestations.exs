defmodule Explorer.Repo.Migrations.AddCeloAttestations do
  use Ecto.Migration

  def change do
    create table(:celo_attestations) do
      add(:attestor_hash, references(:addresses, column: :hash, type: :bytea), null: false)
      add(:attestee_hash, references(:addresses, column: :hash, type: :bytea), null: false)
      add(:identifier, :string, null: false)
      add(:status, :string, null: false)
      add(:block_number, :integer, null: false)
      timestamps(null: false, type: :utc_datetime_usec)
    end

    create_if_not_exists(index(:celo_attestations, [:attestor_hash, :attestee_hash, :identifier], unique: true))
    create_if_not_exists(index(:celo_attestations, [:attestor_hash]))
    create_if_not_exists(index(:celo_attestations, [:attestee_hash]))
  end
end
