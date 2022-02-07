# This file is auto generated, changes will be lost upon regeneration

defmodule Explorer.Celo.ContractEvents.EventMap do
  @moduledoc "Map event names and event topics to concrete contract event structs"

  alias Explorer.Celo.ContractEvents.EventTransformer

  def rpc_to_event_params(logs) when is_list(logs) do
    logs
    |> Enum.map(fn params = %{first_topic: event_topic} ->
      case event_for_topic(event_topic) do
        nil ->
          nil

        event ->
          event
          |> struct!()
          |> EventTransformer.from_params(params)
          |> EventTransformer.to_celo_contract_event_params()
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def celo_contract_event_to_concrete_event(events) when is_list(events) do
    events
    |> Enum.map(fn params = %{name: name} ->
      case event_for_name(name) do
        nil ->
          nil

        event ->
          event
          |> struct!()
          |> EventTransformer.from_celo_contract_event(params)
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def event_for_topic("0x45aac85f38083b18efe2d441a65b9c1ae177c78307cb5a5d4aec8f7dbcaeabfe"),
    do: Elixir.Explorer.Celo.ContractEvents.Election.ValidatorGroupVoteActivatedEvent

  def event_for_topic("0x91ba34d62474c14d6c623cd322f4256666c7a45b7fdaa3378e009d39dfcec2a7"),
    do: Elixir.Explorer.Celo.ContractEvents.Election.EpochRewardsDistributedToVotersEvent

  def event_for_topic("0xae7458f8697a680da6be36406ea0b8f40164915ac9cc40c0dad05a2ff6e8c6a8"),
    do: Elixir.Explorer.Celo.ContractEvents.Election.ValidatorGroupActiveVoteRevokedEvent

  def event_for_topic("0x6f5937add2ec38a0fa4959bccd86e3fcc2aafb706cd3e6c0565f87a7b36b9975"),
    do: Elixir.Explorer.Celo.ContractEvents.Validators.ValidatorEpochPaymentDistributedEvent

  def event_for_name("ValidatorGroupVoteActivated"),
    do: Elixir.Explorer.Celo.ContractEvents.Election.ValidatorGroupVoteActivatedEvent

  def event_for_name("EpochRewardsDistributedToVoters"),
    do: Elixir.Explorer.Celo.ContractEvents.Election.EpochRewardsDistributedToVotersEvent

  def event_for_name("ValidatorGroupActiveVoteRevoked"),
    do: Elixir.Explorer.Celo.ContractEvents.Election.ValidatorGroupActiveVoteRevokedEvent

  def event_for_name("ValidatorEpochPaymentDistributed"),
    do: Elixir.Explorer.Celo.ContractEvents.Validators.ValidatorEpochPaymentDistributedEvent
end
