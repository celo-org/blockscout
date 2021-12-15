defmodule EthereumJSONRPC.Celo.TransactionParsing do

  def parse_legacy_transaction( transaction = %{ "type" => "0x0" }) do
    transaction
    |> base_transaction()
  end

  @optional_parameters %{
    "created" => :created_contract_address_hash,
    "type" => :type
  }

  def base_transaction( transaction = %{
    "blockHash" => block_hash,
    "blockNumber" => block_number,
    "from" => from_address_hash,
    "feeCurrency" => gas_currency_hash,
    "gas" => gas,
    "gasPrice" => gas_price,
    "gatewayFee" => gateway_fee,
    "gatewayFeeRecipient" => gas_fee_recipient_hash,
    "hash" => hash,
    "input" => input,
    "nonce" => nonce,
    "r" => r,
    "s" => s,
    "to" => to_address_hash,
    "transactionIndex" => index,
    "v" => v,
    "value" => value
  }) do
    result = %{
      block_hash: block_hash,
      block_number: block_number,
      from_address_hash: from_address_hash,
      gas: gas,
      gas_price: gas_price,
      gas_currency_hash: gas_currency_hash,
      gas_fee_recipient_hash: gas_fee_recipient_hash,
      gateway_fee: gateway_fee,
      hash: hash,
      index: index,
      input: input,
      nonce: nonce,
      r: r,
      s: s,
      to_address_hash: to_address_hash,
      v: v,
      value: value,
      transaction_index: index
    }

    @optional_parameters
    |> Enum.reduce(result, fn {k,v},acc  ->
      optional_parameter(transaction, acc, k, v)
    end)
  end

  defp optional_parameter(source = %{}, destination = %{}, source_key, destination_key) do
    if Map.has_key?(source, source_key) do
      value = source |> Map.get(source_key)

      destination |> Map.put(destination_key, value)
    else
      destination
    end
  end
end