defmodule Explorer.Repo.Migrations.AddFetchVoterVotesToCeloPendingEpochOperations do
  use Ecto.Migration

  def change do
    alter table(:celo_pending_epoch_operations) do
      add(:fetch_voter_votes, :boolean)
    end
  end
end
