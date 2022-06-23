defmodule Explorer.Repo.Migrations.SetContractEventsCompatibility do
  use Ecto.Migration

  def change do
    execute(
      "ALTER TABLE celo_contract_events ADD COLUMN id bigserial",
      "ALTER TABLE celo_contract_events DROP COLUMN id"
    )

    execute(
      "ALTER TABLE celo_contract_events DROP CONSTRAINT celo_contract_events_pkey",
      "ALTER TABLE celo_contract_events ADD PRIMARY KEY (block_number, log_index)"
    )

    execute(
      "ALTER TABLE celo_contract_events ADD PRIMARY KEY (id)",
      "ALTER TABLE celo_contract_events DROP CONSTRAINT celo_contract_events_pkey"
    )

    execute(
      "CREATE UNIQUE INDEX celo_contract_events_unique_block_number_log_index on celo_contract_events(block_number, log_index)",
      "DROP INDEX IF EXISTS celo_contract_events_unique_block_number_log_index"
    )
  end
end
