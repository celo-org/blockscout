defmodule Explorer.Repo.Migrations.DataMigration do
  @moduledoc """
    Defines a data migration to be run outside of the standard schema migration flow.
  """

  @doc false
  defmacro __using__(opts) do

    batch_size = Keyword.get(opts, :batch_size, 1000)
    throttle = Keyword.get(opts, :throttle, 100)

    quote do
      require Logger
      use Ecto.Migration
      alias Explorer.Celo.Telemetry

      @disable_ddl_transaction true
      @disable_migration_lock true
      @batch_size unquote(batch_size)
      @throttle_ms unquote(throttle)

      def up do
        before()

        initial_value = get_initial_value()

        start_time = Telemetry.start(__MODULE__)
        throttle_change_in_batches(&page_query/1, &do_change/1, initial_value)
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

      defp get_initial_value() do
        initial_value_str = System.get_env("INITIAL_VALUE")

        unless initial_value_str do
          raise "No initial value for data migration provided - please rerun with an environment var INITIAL_VALUE='elixir term'"
        end

        {result, _} = Code.eval_string(initial_value_str)

        result
      end

      def before, do: Logger.info("Starting #{to_string(__MODULE__)}")

      defoverridable before: 0, up: 0
    end
  end

  @doc """
  A query returning a list of ids to be processed in a single batch, accepts an optional starting id to start the
  next page from.
  """
  @callback page_query(any()) :: [any()]

  @callback do_change([any()]) :: [any()]

  @doc "Handle a failed insertion"
  @callback handle_failure([any()]) :: nil
end
