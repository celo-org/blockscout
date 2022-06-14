defmodule Explorer.Repo.Migrations.AddAddressCurrentTokenBalancesOrderingIndex do
  use Ecto.Migration

  def change do
    create(index(:address_current_token_balances, [:value, :address_hash]))
  end
end
