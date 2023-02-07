defmodule Explorer.Celo.Telemetry.Instrumentation.Api do
  @moduledoc "Api metric definitions"

  alias Explorer.Celo.Telemetry.Instrumentation
  use Instrumentation

  def metrics do
    [
      distribution("api_graphql_operation_duration_milliseconds",
        reporter_options: [
          buckets: [
            50,
            100,
            300,
            500,
            :timer.seconds(1),
            :timer.seconds(3),
            :timer.seconds(5),
            :timer.seconds(10),
            :timer.seconds(30),
            :timer.minutes(1)
          ]
        ],
        event_name: [:absinthe, :execute, :operation, :stop],
        measurement: :duration,
        description: "Operation times for requests send to Blockscout API",
        tags: [:name],
        tag_values: fn metadata ->
          if Keyword.has_key?(metadata.options, :operation_name) and is_binary(metadata.options[:operation_name]) do
            Map.put(%{}, :name, metadata.options[:operation_name])
          else
            %{}
          end
        end,
        unit: {:native, :millisecond}
      )
    ]
  end
end
