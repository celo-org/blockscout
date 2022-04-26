defmodule Explorer.Repo.Migrations.CreateSmartContractsTransactionCountsView do
  use Ecto.Migration

  def up do
    execute("""
    create materialized view smart_contract_transaction_counts as
    with last_block_number as (select max(number) - 17280 * 90 as number from blocks)
    select to_address_hash as address_hash, count(*) as transaction_count from transactions where to_address_hash in (select address_hash from smart_contracts) and block_number > (select number from last_block_number) group by to_address_hash;
    """)
  end

  def down do
    execute("""
    drop materialized view if exists smart_contract_transaction_counts
    """)
  end
end
