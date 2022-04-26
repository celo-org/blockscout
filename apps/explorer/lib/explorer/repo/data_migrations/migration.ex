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
          raise "No initial value for data migration provided - please rerun with an env var INITIAL_VALUE='elixir term'"
        end

        {result, _} = Code.eval_string(initial_value_str)

        Logger.info("Using initial value #{inspect(result)}")

        result
      end

      def before, do: Logger.info("Starting #{to_string(__MODULE__)} with batch size #{@batch_size} and throttle #{@throttle_ms} ms")

      defp event_page_query({last_block_number, last_index}) do
        from(
          l in "logs",
          left_join: e in "celo_contract_events",
          on: e.topic == l.first_topic and e.block_number == l.block_number and e.log_index == l.index,
          select: %{
            first_topic: l.first_topic,
            second_topic: l.second_topic,
            third_topic: l.third_topic,
            fourth_topic: l.fourth_topic,
            data: l.data,
            address_hash: l.address_hash,
            transaction_hash: l.transaction_hash,
            block_number: l.block_number,
            index: l.index
          },
          where:
            is_nil(e.topic) and l.first_topic in ^@topics and {l.block_number, l.index} > {^last_block_number, ^last_index},
          order_by: [asc: l.block_number, asc: l.index],
          limit: @batch_size
        )
      end

      defp event_change(to_change) do
        params =
          to_change
          |> Explorer.Celo.ContractEvents.EventMap.rpc_to_event_params()
            # explicitly set timestamps as insert_all doesn't do this automatically
          |> then(fn events ->
            t = Timex.now()

            events
            |> Enum.map(fn event ->
              {:ok, contract_address_hash} = Address.dump(event.contract_address_hash)

              event =
                case event.transaction_hash do
                  nil ->
                    event

                  hash ->
                    {:ok, transaction_hash} = Full.dump(hash)
                    event |> Map.put(:transaction_hash, transaction_hash)
                end

              event
              |> Map.put(:inserted_at, t)
              |> Map.put(:updated_at, t)
              |> Map.put(:contract_address_hash, contract_address_hash)
            end)
          end)

        {inserted_count, results} =
          Explorer.Repo.insert_all("celo_contract_events", params, returning: [:block_number, :log_index])

        if inserted_count != length(to_change) do
          not_inserted =
            to_change
            |> Enum.map(&Map.take(&1, [:block_number, :log_index]))
            |> MapSet.new()
            |> MapSet.difference(MapSet.new(results))
            |> MapSet.to_list()

          not_inserted |> Enum.each(&handle_non_update/1)
        end

        last_key =
          results
          |> Enum.map(fn %{block_number: block_number, log_index: index} -> {block_number, index} end)
          |> Enum.max()

        [last_key]
      end

      defoverridable before: 0, up: 0
    end
  end
end
