defmodule Explorer.Repo.Migrations.UpdatedAtIndices do
  use Ecto.Migration

  @disable_migration_lock true
  @disable_ddl_transaction true

  @tables ~w(
    token_transfers
    blocks
    celo_wallets
    address_current_token_balances
    address_token_balances
  )a

  def change do
    for table <- @tables, do: create(index(table, [:updated_at], concurrently: true))
  end
end
