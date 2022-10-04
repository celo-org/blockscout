defmodule Indexer.Prometheus.CeloInstrumenter do
  @moduledoc "Instrumentation for Celo telemetry"

  use Prometheus.Metric

  def setup do
    event_config = Application.get_env(:indexer, :telemetry_config)

    event_config |> Enum.each(&(configure_event(&1)))
  end

  def configure_event(event_config) do
    case process_config(event_config) do
      [name, type, label, meta] ->
        attach_event(name, type, label, meta)
      {:error, msg} -> Logger.error("Error configuring event #{inspect(event_config)}: #{msg}")
    end
  end

  def attach_event(name, :histogram, label, %{buckets: buckets, metric_labels: metric_labels, help: help} = meta) do
    Histogram.new(
      name: label,
      buckets: buckets,
      duration_unit: false,
      labels: metric_labels,
      help: help
    )

    :telemetry.attach(handler_id(name), name, &CeloInstrumenter.handle_event/4, %{type: :histogram, label: label})
  end

  def attach_event(name, _type, _label, _meta), do: Logger.info("Not adding metric nope #{name |> inspect()}")

  defp handler_id(event_name), do: "event_handler_id_#{event_name |> to_string()}"

  def handle_event(_name, measurements, _metadata, %{type: :histogram, label: label} = config) when is_map(measurements) do
    measurements
    |> Enum.each(fn {name, value} ->
      Histogram.observe(
        [name: label, labels: [name]],
        value
      )
    end)
  end

  def handle_event(name, _measurements, _metadata, _config) do
    Logger.error("unhandled metric #{name |> inspect()}")
  end

  defp process_config(event) do
    name = Keyword.get(event, :name, {:error, "no event name"})
    type = Keyword.get(event, :type, {:error, "no metric type"})
    label = Keyword.get(event, :label, {:error, "no metric label"})
    meta = Keyword.get(event, :meta, %{})

    metric_def = [name, type, label, meta]

    # return error tuple if that is found in metric_def, otherwise return metric_def
    metric_def
    |> Enum.find(metric_def,
         fn {:error, _} -> true
                           fn n -> false end
         end)
  end

end
