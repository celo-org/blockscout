defmodule Explorer.Celo.ContractEvents.Common do
  def decode_event(topic, type) do
    topic
    |> extract_hash()
    |> ABI.TypeDecoder.decode_raw([type])
    |> List.first()
    |> convert_result(type)
  end

  defp extract_hash(event_data), do: event_data |> String.trim_leading("0x") |> Base.decode16!(case: :lower)

  def convert_result(result, :address) do
    {:ok, address} = Explorer.Chain.Hash.Address.cast(result)
    address
  end
end