defmodule Explorer.Repo.Local.Migrations.RecommendedTxIndex do
  use Ecto.Migration

  def change do
    create_if_not_exists(
      index(
        :transactions,
        [
          :block_hash,
          :hash
        ],
        name: "transactions_block_hash_hash",
        concurrently: true
      )
    )
  end
end
