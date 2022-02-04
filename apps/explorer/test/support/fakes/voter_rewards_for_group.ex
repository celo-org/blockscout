defmodule Explorer.Fakes.VoterRewardsForGroup do
  def calculate do
    %{
      total: 350,
      epochs: [
        %{amount: 80, date: ~U[2022-01-01 17:42:43.162804Z], epoch_number: 619},
        %{amount: 20, date: ~U[2022-01-02 17:42:43.162804Z], epoch_number: 620},
        %{amount: 75, date: ~U[2022-01-03 17:42:43.162804Z], epoch_number: 621},
        %{amount: 31, date: ~U[2022-01-04 17:42:43.162804Z], epoch_number: 622},
        %{amount: 77, date: ~U[2022-01-05 17:42:43.162804Z], epoch_number: 623},
        %{amount: 67, date: ~U[2022-01-06 17:42:43.162804Z], epoch_number: 624}
      ]
    }
  end
end
