defmodule Indexer.Prometheus.DBInstrumenter do
  @moduledoc """
  Instrument db related metrics.
  """
  use Prometheus.Metric

  def setup do
    counter_events = [
      [:deadlocks]
    ]

    gauge_events = [
      [:locks],
      [:longest_query_name],
      [:longest_query_duration]
    ]

    Enum.each(counter_events, &setup_counter/1)
    Enum.each(gauge_events, &setup_gauge/1)
  end

  defp setup_counter(event) do
    name = "indexer_dbs_#{Enum.join(event, "_")}"

    Counter.declare(
      name: String.to_atom("#{name}_total"),
      help: "Total count of tracking for db event #{name}"
    )

    :telemetry.attach(name, [:indexer, :db | event], &handle_inc_event/4, nil)
  end

  defp setup_gauge(event) do
    name = "indexer_db_#{Enum.join(event, "_")}"

    Gauge.declare(
      name: String.to_atom("#{name}_current"),
      help: "Current number of tracking for db event #{name}"
    )

    :telemetry.attach(name, [:indexer, :db | event], &handle_set_event/4, nil)
  end

  def handle_inc_event([:indexer, :db, :deadlocks], _value, _metadata, _config) do
    Counter.inc(name: :indexer_db_deadlocks_total)
  end

  def handle_set_event([:indexer, :db, :locks], %{value: val}, _metadata, _config) do
    Gauge.set([name: :indexer_db_locks_current], val)
  end

  def handle_set_event([:indexer, :db, :longest_query_name], %{value: val}, _metadata, _config) do
    Gauge.set([name: :indexer_db_longest_query_name_current], val)
  end

  def handle_set_event([:indexer, :db, :longest_query_duration], %{value: val}, _metadata, _config) do
    Gauge.set([name: :indexer_db_longest_query_duration_current], val)
  end
end
