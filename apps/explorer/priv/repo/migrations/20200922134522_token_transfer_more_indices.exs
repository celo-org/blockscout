defmodule Explorer.Repo.Migrations.CreateInternalTxIndex do
  use Ecto.Migration

  def change do
    create(index(:token_transfers, ["block_number DESC, amount DESC, log_index DESC"]))

    create(
      index(:token_transfers, ["block_number DESC, transaction_hash DESC, from_address_hash DESC, to_address_hash DESC"])
    )
  end
end
