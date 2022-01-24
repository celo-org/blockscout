alias Explorer.Chain.Log

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

  def from(log = %Log{first_topic: "0x45aac85f38083b18efe2d441a65b9c1ae177c78307cb5a5d4aec8f7dbcaeabfe"}) do
    #account and group a


    %__MODULE__{
      transaction_hash: log.transaction_hash,
      block_hash: log.block_hash,
      contract_address_hash: log.address_hash,
      log_index: log.index,

      #event specific parameters
    }
  end
end