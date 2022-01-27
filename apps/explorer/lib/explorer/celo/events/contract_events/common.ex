defmodule Explorer.Celo.ContractEvents.Common do
  def decode_event(topic, type) do
    topic
    |> extract_hash()
    |> ABI.TypeDecoder.decode_raw([type])
    |> List.first()
    |> convert_result(type)
  end

  def decode_data(%Explorer.Chain.Data{bytes: bytes}, types), do: decode_data(bytes, types)

  def decode_data("0x" <> data, types) do
    data
    |> Base.decode16!(case: :lower)
    |> decode_data(types)
  end

  def decode_data(data, types) when is_binary(data), do: data |> ABI.TypeDecoder.decode_raw(types)

  defp extract_hash(event_data), do: event_data |> String.trim_leading("0x") |> Base.decode16!(case: :lower)

  #todo: search abis for indexed values that are not addresses
  defp convert_result(result, :address) do
    "0x" <> Base.encode16(result, case: :lower)
    #{:ok, address} = Explorer.Chain.Hash.Address.cast(result)
    #address
  end

  def extract_common_event_params(event) do
    %{
      name: event.name,
      log_index: event.log_index,
      transaction_hash: event.transaction_hash |> to_string(),
      contract_address_hash: event.contract_address_hash |> to_string(),
      block_hash: event.block_hash |> to_string()
    }
  end
end