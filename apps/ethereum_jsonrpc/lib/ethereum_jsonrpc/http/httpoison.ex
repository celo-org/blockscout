defmodule EthereumJSONRPC.HTTP.HTTPoison do
  @moduledoc """
  Uses `HTTPoison` for `EthereumJSONRPC.HTTP`
  """

  alias EthereumJSONRPC.HTTP
  alias Indexer.Prometheus.ResponseETS

  require UUID

  @behaviour HTTP

  @impl HTTP
  def json_rpc(url, json, options, method) when is_binary(url) and is_list(options) do
    id = UUID.uuid4()
    ResponseETS.put(id, %{:method => method, :start => :os.system_time(:millisecond)})
    case HTTPoison.post(url, json, [{"Content-Type", "application/json"}], options) do
      {:ok, %HTTPoison.Response{body: body, status_code: status_code}} ->
        ResponseETS.put(id, %{:method => method, :finish => :os.system_time(:millisecond)})
        {:ok, %{body: body, status_code: status_code}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        ResponseETS.delete(id)
        {:error, reason}
    end
  end
end
