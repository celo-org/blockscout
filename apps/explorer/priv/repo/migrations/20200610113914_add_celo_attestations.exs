defmodule Explorer.Repo.Migrations.AddCeloAttestations do
  use Ecto.Migration

  def change do
    create table(:celo_attestations, primary_key: false) do
      add(:attestor, references(:addresses, column: :hash, type: :bytea), null: false)
      add(:attestee, references(:addresses, column: :hash, type: :bytea), null: false)
      add(:identifier, :string, null: false)
      add(:status, :string, null: false)
      add(:block_number, :integer, null: false)
      timestamps(null: false, type: :utc_datetime_usec)
    end

    create_if_not_exists(index(:celo_attestations, [:attestor, :attestee, :identifier], unique: true))
    create_if_not_exists(index(:celo_attestations, [:attestor]))
    create_if_not_exists(index(:celo_attestations, [:attestee]))
  end
end
