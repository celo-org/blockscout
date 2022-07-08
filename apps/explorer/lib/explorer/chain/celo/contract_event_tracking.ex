defmodule Explorer.Chain.Celo.ContractEventTracking do
  @moduledoc """
    Representing an intention to track incoming and historical contract events from a given verified `smart_contract`
  """
  require Logger

  alias __MODULE__
  alias Explorer.Repo
  use Explorer.Schema
  import Ecto.Query

  @type t :: %__MODULE__{
               stat_type: String.t(),
               value: non_neg_integer()
             }
  schema "clabs_contract_event_trackings" do
  end
end