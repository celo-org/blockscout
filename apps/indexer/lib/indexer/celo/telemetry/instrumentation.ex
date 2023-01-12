defmodule Indexer.Celo.Telemetry.Instrumentation do
  alias Explorer.Celo.Telemetry.Instrumentation

  use Instrumentation

  def metrics() do
    [
      counter("indexer.import.ingested",
        event_name: [:blockscout, :ingested],
        measurement: :count,
        description: "Blockchain primitives ingested via `Import.all` by type",
        tags: [:type]
      )
    ]
  end
end