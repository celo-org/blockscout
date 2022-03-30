defmodule BlockScoutWeb.VerifiedContractsView do
  use BlockScoutWeb, :view

  alias Explorer.Chain.Wei
  alias Explorer.Chain.SmartContract
  alias Explorer.Chain.Address

  def detect_license(contract) do
    cond do
      license = spdx_tag(contract.contract_source_code) ->
        license

      Explorer.Celo.CoreContracts.is_core_contract_address?(contract.address.hash) ->
        "LGPL-3.0"

      true ->
        "Unknown"
    end
  end

  def spdx_tag(source) do
    ~r/SPDX-License-Identifier:\s+(.*)/
    |> Regex.run(source, capture: :all_but_first)
  end

  def contract_balance(%SmartContract{address: %Address{fetched_coin_balance: balance}}) when not is_nil(balance) do
    balance
    |> Wei.to(:ether)
    |> Decimal.round(3)
  end

  def contract_balance(_contract) do
    0
  end
end