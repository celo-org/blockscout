defmodule EventStream.Metrics do
  alias Explorer.Celo.Telemetry.Instrumentation
  use Instrumentation

  def metrics do
    [
      counter("blockscout.event_stream.flush")
    ]
  end
end