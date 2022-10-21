defmodule Indexer.Celo.Telemetry.Helper do
  @moduledoc "Helper functions for telemetry event processing"

  @doc """
    Filters out changes from the full list of imports to only those that we care about
    This is necessary as Import.all will return a mapping of each Ecto.Multi stage id to count of rows affected
  """
  def filter_imports(changes) do
    changes
    |> Enum.reduce(%{}, fn import, acc ->
      case take_import(import) do
        {key, count} ->  Map.put(acc, key, count)
        nil -> acc
      end
    end)

  end

  defp take_import(epoch_rewards = {:celo_epoch_rewards, _}), do: epoch_rewards
  defp take_import({:insert_account_epoch_items, count}), do: {:celo_account_epoch, count}
  defp take_import(addresses = {:addresses, _}), do: addresses
  defp take_import(tx = {:transactions, _}), do: tx
  defp take_import(blocks = {:blocks, _}), do: blocks
  defp take_import(t = {:tokens, _}), do: t
  defp take_import(itx = {:internal_transactions, _}), do: itx
  defp take_import(_), do: nil
end