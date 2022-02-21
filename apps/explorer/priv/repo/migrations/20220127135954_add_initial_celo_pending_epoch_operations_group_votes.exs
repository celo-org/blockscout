defmodule Explorer.Repo.Migrations.AddInitialCeloPendingEpochOperationsGroupVotes do
  use Ecto.Migration

  def up do
    execute("""
    WITH epoch_blocks AS (
    SELECT i * 17280 as block_number FROM generate_series(1, (SELECT (MAX(number)/17280) FROM blocks)) as i
    ), epoch_block_hashes AS
    (SELECT b.hash, true as epoch, (CASE WHEN b.number < 172800 THEN false ELSE true END) as validator_group FROM epoch_blocks eb LEFT JOIN blocks b ON b.number = eb.block_number)
    INSERT INTO celo_pending_epoch_operations (
    block_hash, fetch_epoch_rewards, fetch_validator_group_data, inserted_at, updated_at
    ) SELECT *, NOW(), NOW() FROM epoch_block_hashes;
    """)
  end

  def down do
    execute("delete from celo_pending_epoch_operations;")
  end
end
