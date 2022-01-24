alias Explorer.Chain.Log
alias Explorer.Celo.ContractEvents.EventTransformer

defmodule Explorer.Celo.ContractEvents.Election.ValidatorGroupVoteActivatedEvent do
  @moduledoc """
  Struct modelling the Election.ValidatorGroupVoteActivated event

  ValidatorGroupVoteActivated(
      address indexed account,
      address indexed group,
      uint256 value,
      uint256 units
    );
  """

  defstruct [
    :transaction_hash, :block_hash, :contract_address_hash, :log_index,
    :account,
    :group,
    :value,
    :units,
    name: "ValidatorGroupVoteActivatedEvent"
  ]

  defimpl EventTransformer do
    alias Explorer.Celo.ContractEvents.Election.ValidatorGroupVoteActivatedEvent

    def from_log(_, log = %Log{}) do
      [value, units] = ABI.TypeDecoder.decode_raw(log.data.bytes, [{:uint, 256}, {:uint, 256}])
      account = ABI.TypeDecoder.decode(log.second_topic, [:address])
      group = ABI.TypeDecoder.decode(log.third_topic, [:address])

      %ValidatorGroupVoteActivatedEvent{
        transaction_hash: log.transaction_hash,
        block_hash: log.block_hash,
        contract_address_hash: log.address_hash,
        log_index: log.index,
        #event specific parameters
        account: account,
        group: group,
        value: value,
        units: units
      }
    end
    def from_params(_, _params) do
      "lol"
    end
    def from_contract_event(_, _contract) do
      "lol"
    end

    def to_celo_contract_event(_) do
      "lol"
    end
  end
end