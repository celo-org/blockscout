defmodule Indexer.Fetcher.InternalTransaction.Util do
  @doc """
    A utility module for common internal transaction fetching functions
  """

  @doc "Remove child traces of errored function calls"
  def remove_failed_creations(internal_transactions_params) do
    internal_transactions_params
    |> Enum.map(fn internal_transaction_param ->
      transaction_index = internal_transaction_param[:transaction_index]
      block_number = internal_transaction_param[:block_number]

      failed_parent =
        internal_transactions_params
        |> Enum.filter(fn internal_transactions_param ->
          internal_transactions_param[:block_number] == block_number &&
            internal_transactions_param[:transaction_index] == transaction_index &&
            internal_transactions_param[:trace_address] == [] && !is_nil(internal_transactions_param[:error])
        end)
        |> Enum.at(0)

      if failed_parent do
        internal_transaction_param
        |> Map.delete(:created_contract_address_hash)
        |> Map.delete(:created_contract_code)
        |> Map.delete(:gas_used)
        |> Map.delete(:output)
        |> Map.put(:error, failed_parent[:error])
      else
        internal_transaction_param
      end
    end)
  end

  def import_first_trace(internal_transactions_params) do
    imports =
      Chain.import(%{
        internal_transactions: %{params: internal_transactions_params, with: :blockless_changeset},
        timeout: :infinity
      })

    case imports do
      {:error, step, reason, _changes_so_far} ->
        Logger.error(
          fn ->
            [
              "failed to import first trace for tx: ",
              inspect(reason)
            ]
          end,
          step: step
        )
    end
  end
end
