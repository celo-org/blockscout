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

  defp take_import({:insert_celo_election_rewards_items, count}), do: {:celo_election_rewards, count}
  defp take_import({:insert_celo_params_items, count}), do: {:celo_params, count}
  defp take_import({:insert_celo_signer_items, count}), do: {:celo_signers, count}
  defp take_import({:insert_validator_group_items, count}), do: {:celo_validator_group, count}
  defp take_import({:insert_validator_history_items, count}), do: {:celo_validator_history, count}
  defp take_import({:insert_validator_status_items, count}), do: {:celo_validator_status, count}
  defp take_import({:insert_celo_accounts, count}), do: {:celo_accounts, count}
  defp take_import({:insert_celo_validators, count}), do: {:celo_validators, count}
  defp take_import({:insert_wallets, count}), do: {:celo_wallets, count}
  defp take_import({:insert_celo_voters, count}), do: {:celo_voters, count}
  defp take_import({:insert_account_epoch_items, count}), do: {:celo_account_epoch, count}
  defp take_import(cl = {:celo_unlocked, _}), do: cl
  defp take_import(cce = {:celo_contract_event, _}), do: cce
  defp take_import(ccc = {:celo_core_contracts, _}), do: ccc
  defp take_import(epoch_rewards = {:celo_epoch_rewards, _}), do: epoch_rewards

  defp take_import({:tracked_contract_events, count}), do: {:contract_event, count}

  defp take_import(address_coin_balances_daily = {:address_coin_balances_daily, _}), do: address_coin_balances_daily
  defp take_import(address_coin_balances = {:address_coin_balances, _}), do: address_coin_balances
  defp take_import(an = {:insert_names, count}), do: {:address_names, count}
  defp take_import(address_token_balances = {:address_token_balances, _}), do: address_token_balances
  defp take_import(address_current_token_balances = {:address_current_token_balances, _}), do: address_current_token_balances
  defp take_import(addresses = {:addresses, _}), do: addresses
  defp take_import(tx = {:transactions, _}), do: tx
  defp take_import(blocks = {:blocks, _}), do: blocks
  defp take_import(tt = {:token_transfers, _}), do: tt
  defp take_import(t = {:tokens, _}), do: t
  defp take_import(logs = {:logs, _}), do: logs
  defp take_import(itx = {:internal_transactions, _}), do: itx

  defp take_import(_), do: nil
end