defmodule BlockScoutWeb.Celo.Telemetry.Instrumentation.Web do
  @moduledoc "Custom celo block_scout_web metric definitions"

  alias Explorer.Celo.Telemetry.Instrumentation
  use Instrumentation

  def metrics do
    [
      last_value("num_sanctioned_addresses",
        event_name: [:blockscout, :web, :sanctioned_addresses],
        measurement: :value,
        description: "Total number of sanctioned addresses blocked from UI interaction"
      )
    ]
  end
end
