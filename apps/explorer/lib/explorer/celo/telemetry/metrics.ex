defmodule Explorer.Celo.Telemetry.Metrics do

  def summary(event_id, opts \\ []) do
    id = get_id(event_id)
  end


  defp get_id(id) when is_list(id), do: id
  defp get_id(id) when is_binary(id), do: String.split(".") |> Enum.map(&String.to_atom/1)
end