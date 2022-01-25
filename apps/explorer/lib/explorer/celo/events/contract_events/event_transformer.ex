defprotocol Explorer.Celo.ContractEvents.EventTransformer do

  @doc "Create a concrete event instance from Explorer.Chain.Log instance"
  def from_log(event, log)

  @doc "Create a concrete event instance from log params as output by EthereumJSONRPC"
  def from_params(event, eth_jsonrpc_log_params)

  @doc "Create a concrete event instance from a generic CeloContractEvent"
  def from_celo_contract_event(event, celo_event)

  @doc "Convert an event instance into parameters for DB insertion as a generic CeloContractEvent"
  def to_celo_contract_event_params(event)
end