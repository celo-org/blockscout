defmodule Explorer.Repo.Migrations.DataMigration do
  @moduledoc """
    Defines a data migration to be run outside of the standard schema migration flow.
  """

  @doc false
  defmacro __using__(opts) do
    alias Explorer.Celo.Telemetry

    batch_size = Keyword.get(opts, :batch_size, 1000)
    throttle = Keyword.get(opts, :throttle, 100)

    quote do
      use Ecto.Migration

      @disable_ddl_transaction true
      @disable_migration_lock true
      @batch_size unquote(batch_size)
      @throttle_ms unquote(throttle)

      @behaviour Explorer.Repo.Migrations.DataMigration

      def up do
        start_time = Telemetry.start(__MODULE__)
        throttle_change_in_batches(&page_query/1, &do_change/1)
        Telemetry.stop(__MODULE__, start_time)
      end

      defp throttle_change_in_batches(query_fun, change_fun, last_pos \\ {0, 0})
      defp throttle_change_in_batches(_query_fun, _change_fun, nil), do: :ok

      defp throttle_change_in_batches(query_fun, change_fun, last_pos) do
        case repo().all(query_fun.(last_pos), log: :info, timeout: :infinity) do
          [] ->
            :ok

          ids ->
            start_time = System.monotonic_time()
            results = change_fun.(List.flatten(ids))
            duration = System.monotonic_time() - start_time
            duration_ms = System.convert_time_unit(duration, :native, :millisecond)

            Logger.info("Inserted #{length(ids)} rows in #{duration_ms} ms")

            next_page = results |> Enum.reverse() |> List.first()
            Process.sleep(@throttle_ms)
            throttle_change_in_batches(query_fun, change_fun, next_page)
        end
      end
    end

    @doc """
    A query returning a list of ids to be processed in a single batch, accepts an optional starting id to start the
    next page from.
    """
    @callback page_query(start_from) :: [any()]

    @doc "Perform the tranformation with the list of ids to operate upon, returns a list of inserted ids"
    @callback do_change(batch_of_ids) :: [any()]

    @doc "Handle a failed insertion"
    @callback handle_failure(failed) :: nil
  end
end
