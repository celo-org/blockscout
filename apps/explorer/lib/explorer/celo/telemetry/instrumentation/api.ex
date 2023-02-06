defmodule Explorer.Celo.Telemetry.Instrumentation.Api do
  @moduledoc "Api metric definitions"

  alias Explorer.Celo.Telemetry.Instrumentation
  use Instrumentation

  def metrics do
    [
      distribution("api_graphql_resolution_duration_milliseconds",
        reporter_options: [
          buckets: [
            30,
            50,
            100,
            200,
            300,
            500,
            :timer.seconds(1),
            :timer.seconds(2),
            :timer.seconds(3),
            :timer.seconds(5),
            :timer.seconds(10),
            :timer.seconds(20),
            :timer.seconds(30),
            :timer.minutes(1)
          ]
        ],
        event_name: [:absinthe, :resolve, :field, :stop],
        measurement: :duration,
        description: "Resolution times for requests send to Blockscout API",
        tags: [:path],
        tag_values: fn metadata ->
          path = Absinthe.Resolution.path(metadata.resolution)

          Map.put(%{}, :path, path)
        end,
        unit: {:native, :millisecond}
      )
    ]
  end
end
