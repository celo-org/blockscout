defmodule BlockScoutWeb.API.RPC.TokenView do
  use BlockScoutWeb, :view

  alias BlockScoutWeb.API.RPC.RPCView

  def render("gettoken.json", %{token: token}) do
    RPCView.render("show.json", data: prepare_token(token))
  end

  def render("tokentx.json", %{token_transfers: token_transfers}) do
    data = Enum.map(token_transfers, &prepare_token_transfer/1)
    RPCView.render("show.json", data: data)
  end

  def render("error.json", assigns) do
    RPCView.render("error.json", assigns)
  end

  defp prepare_token(token) do
    %{
      "type" => token.type,
      "name" => token.name,
      "symbol" => token.symbol,
      "totalSupply" => to_string(token.total_supply),
      "decimals" => to_string(token.decimals),
      "contractAddress" => to_string(token.contract_address_hash),
      "cataloged" => token.cataloged
    }
  end

  # {

  #     "data": "0x0000000000000000000000000000000000000000000000000000000000000001",
  #   }

  defp prepare_token_transfer(token_transfer) do
    %{
      "blockNumber" => integer_to_hex(token_transfer.block_number),
      "timeStamp" => datetime_to_hex(token_transfer.block_timestamp),
      "transactionHash" => "#{token_transfer.transaction_hash}",
      "address" => "#{token_transfer.token_contract_address_hash}",
      "transactionIndex" => integer_to_hex(token_transfer.transaction_index),
      "logIndex" => integer_to_hex(token_transfer.log_index),
      "gasPrice" => decimal_to_hex(token_transfer.gas_price.value),
      "gasUsed" => decimal_to_hex(token_transfer.gas_used),
      "feeCurrency" => "#{token_transfer.gas_currency_hash}",
      "gatewayFeeRecipient" => "#{token_transfer.gas_fee_recipient_hash}",
      "gatewayFee" => "#{token_transfer.gateway_fee}",
      "topics" => get_topics(token_transfer),
      "data" => "#{token_transfer.data}"
    }
  end

  defp integer_to_hex(integer), do: Integer.to_string(integer, 16)

  defp decimal_to_hex(decimal) do
    decimal
    |> Decimal.to_integer()
    |> integer_to_hex()
  end

  defp datetime_to_hex(datetime) do
    datetime
    |> DateTime.to_unix()
    |> integer_to_hex()
  end

  defp get_topics(%{
         first_topic: first_topic,
         second_topic: second_topic,
         third_topic: third_topic,
         fourth_topic: fourth_topic
       }) do
    [first_topic, second_topic, third_topic, fourth_topic]
  end
end
