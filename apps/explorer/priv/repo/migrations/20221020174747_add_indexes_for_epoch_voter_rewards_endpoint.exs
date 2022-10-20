defmodule Explorer.Repo.Migrations.AddIndexesForEpochVoterRewardsEndpoint do
  use Ecto.Migration

  def change do
    create(
      index(:celo_election_rewards, [
        "block_timestamp DESC, reward_type ASC, account_hash ASC, associated_account_hash ASC"
      ])
    )
  end
end
