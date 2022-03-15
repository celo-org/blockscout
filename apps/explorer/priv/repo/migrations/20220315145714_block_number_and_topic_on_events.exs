defmodule Explorer.Repo.Migrations.BlockNumberAndTopicOnEvents do
  use Ecto.Migration

  def up do
    # add new fields
    alter table(:celo_contract_events) do
      add(:block_number, :integer)
      add(:topic, :string)
    end

    # assert change is applied to db
    flush()

    # get block_number and event topic from "parent" log row and update existing event rows
    from(e in "celo_contract_events",
    join: l in "logs",
    on: {l.block_hash, l.index} == {e.block_hash, e.log_index},
    update: [set: [block_number: l.block_number, topic: l.first_topic]])
    |> Repo.update_all([])

    #use block_number in primary key
    alter table(:celo_contract_events) do
      remove(:block_hash)
      modify(:block_number, primary_key: true, null: false)
      modify(:topic, null: false)
    end

    #add indices to block_number and topic
    create index(:celo_contract_events, :block_number)
    create index(:celo_contract_events, :topic)
  end

  def down do
    alter table(:celo_contract_events) do
      add(:block_hash, :string)
    end

    flush()

    from(e in "celo_contract_events",
      join: l in "logs",
      on: {l.block_hash, l.index} == {e.block_hash, e.log_index},
      update: [set: [block_hash: l.block_hash]])
    |> Repo.update_all([])

    alter table(:celo_contract_events) do
      remove(:block_number)
      remove(:topic)
      modify(:block_hash, primary_key: true, null: false)
    end
  end
end
