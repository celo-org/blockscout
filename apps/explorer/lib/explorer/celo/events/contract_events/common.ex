defmodule Explorer.Celo.ContractEvents.Common do
  @doc "Decode a single point of event data of a given type from a given topic"
  def decode_event(topic, type) do
    topic
    |> extract_hash()
    |> ABI.TypeDecoder.decode_raw([type])
    |> List.first()
    |> convert_result(type)
  end

  @doc "Decode event data of given types from log data"
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
    Base.encode16(result, case: :lower)
    #{:ok, address} = Explorer.Chain.Hash.Address.cast(result)
    #address
  end

  def extract_common_event_params(event) do
    #set hashes explicitly to nil rather than empty string when they do not exist
    [:transaction_hash, :contract_address_hash, :block_hash]
    |> Enum.into(%{}, fn key ->
      case Map.get(event, key)  do
        nil -> {key, nil}
        v -> {key, v}
      end
    end)
    |> Map.put(:name, event.name)
    |> Map.put(:log_index, event.log_index)
  end

  @doc "Store address in postgres json format to make joins work with indices"
  def format_address_for_postgres_json(address = "\\x" <> _rest),  do: address
  def format_address_for_postgres_json("0x" <> rest),  do: format_address_for_postgres_json(rest)
  def format_address_for_postgres_json(address),  do: "\\x" <> address

  @doc "Alias for format_address_for_postgres_json/1"
  defdelegate fa(address), to: __MODULE__, as: :format_address_for_postgres_json

  @doc "Convert postgres hex string to Explorer.Chain.Hash.Address instance"
  def cast_address("\\x" <> hash) do
    Explorer.Chain.Hash.Address.cast(hash)
  end

  @doc "Alias for cast_address/1"
  defdelegate ca(address), to: __MODULE__, as: :cast_address
end