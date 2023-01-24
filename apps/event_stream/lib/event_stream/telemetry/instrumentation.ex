defmodule EventStream.Metrics do
  alias Explorer.Celo.Telemetry.Instrumentation
  use Instrumentation

  def metrics do
    [
      counter("lol.party.count")
    ]
  end
end