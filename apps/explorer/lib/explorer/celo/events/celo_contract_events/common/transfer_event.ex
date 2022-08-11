defmodule Explorer.Celo.ContractEvents.Common.TransferEvent do
  @moduledoc """
  Struct modelling the Transfer event from the Stabletoken, Goldtoken, Erc20, Stabletokenbrl, Stabletokeneur Celo core contracts.
  """
  alias Explorer.Repo
  alias Explorer.Chain.{CeloContractEvent, CeloCoreContract}

  use Explorer.Celo.ContractEvents.Base,
    name: "Transfer",
    topic: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"

  alias Explorer.Celo.ContractEvents.EventMap

  event_param(:from, :address, :indexed)
  event_param(:to, :address, :indexed)
  event_param(:value, {:uint, 256}, :unindexed)

  def reserve_bolster(epoch_block_number) do
    query =
      from(
        cce in CeloContractEvent,
        join: ccc_to in CeloCoreContract,
        on: fragment("?::bytea = cast(?->>'to' AS bytea)", ccc_to.address_hash, cce.params),
        join: celo_token in CeloCoreContract,
        on: celo_token.address_hash == cce.contract_address_hash,
        where: cce.name == "Transfer",
        where: ccc_to.name == "Reserve",
        where: celo_token.name == "GoldToken",
        where: fragment("?->>'from' = '\\x0000000000000000000000000000000000000000'", cce.params),
        where: cce.block_number == ^epoch_block_number
      )

    event = Repo.one(query)

    unless is_nil(event) do
      EventMap.celo_contract_event_to_concrete_event(event)
    else
      nil
    end
  end
end
