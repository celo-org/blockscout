defprotocol Explorer.Celo.ContractEvents.EventTransformer do

  def from_log(event, log)
  def from_params(event, eth_jsonrpc_log_params)
  def from_contract_event(event, celo_event)

  def to_celo_contract_event(event)
end