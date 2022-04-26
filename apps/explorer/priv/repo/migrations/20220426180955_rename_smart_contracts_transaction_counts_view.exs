defmodule Explorer.Repo.Migrations.RenameSmartContractsTransactionCountsView do
  use Ecto.Migration

  def up do
    execute("""
    alter materialized view smart_contract_transaction_counts rename to smart_contracts_transaction_counts;
    """)
  end

  def down do
    execute("""
    alter materialized view smart_contracts_transaction_counts rename to smart_contract_transaction_counts;
    """)
  end
end
