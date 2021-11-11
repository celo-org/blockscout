defmodule Explorer.Repo.Migrations.RenameCeloVoterRewardsToCeloEpochRewards do
  use Ecto.Migration

  def change do
    rename(table(:celo_voter_rewards), to: table(:celo_epoch_rewards))
  end
end
