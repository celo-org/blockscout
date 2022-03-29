defmodule BlockScoutWeb.VerifiedContractsView do
  use BlockScoutWeb, :view

  def detect_license(contract) do
    cond do
      license = spdx_tag(contract.contract_source_code) ->
        license

      Explorer.Celo.CoreContracts.is_core_contract_address?(contract.address) ->
        "Celo"

      true ->
        "Unknown"
    end
  end

  def spdx_tag(source) do
    ~r/SPDX-License-Identifier:\s+(.*)/
    |> Regex.run(source, capture: :all_but_first)
  end
end