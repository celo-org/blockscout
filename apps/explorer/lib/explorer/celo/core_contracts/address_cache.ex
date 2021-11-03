defmodule Explorer.Celo.CoreContracts do
  @moduledoc """
    Caches the addresses of core contracts on various celo networks
  """

  alias HTTPoison.Response


  #address of the registry contract, same across networks
@registry_address "0x000000000000000000000000000000000000ce10"

#full list of core contracts, see https://github.com/celo-org/celo-monorepo/blob/master/packages/protocol/lib/registry-utils.ts
@core_contracts ~w(Accounts Attestations BlockchainParameters DoubleSigningSlasher DowntimeSlasher Election EpochRewards Escrow Exchange ExchangeEUR FeeCurrencyWhitelist Freezer GasPriceMinimum GoldToken Governance GovernanceSlasher GovernanceApproverMultiSig GrandaMento LockedGold Random Reserve ReserveSpenderMultiSig SortedOracles StableToken StableTokenEUR TransferWhitelist Validators)

#init - load cache based on environment

  def get_core_contract_address("Registry"), do: @registry_address
  def get_core_contract_address(name) do

  end

  def write_cache(filename) do

  end


  @address_for_string_signature "getAddressForString(string)"

  def full_cache_build(url) do
    @core_contracts
    |> Enum.reduce(%{}, fn name, acc ->
      Map.put(acc, name, query_registry(name, url))
    end)
  end

  def request_for_name(name, id \\ 777) do
    request_data = @address_for_string_signature
      |> ABI.encode([name])
      |> Base.encode16(case: :lower)
      |> then(&("0x"<> &1))

    %{jsonrpc: "2.0", method: "eth_call", params: [ %{ to: @registry_address, data: request_data }, "latest" ], id: id }
    |> Jason.encode!()
  end

  def query_registry(name, registry_url) do
    result =
      name
      |> request_for_name()
      |> perform_request(registry_url)
      |> transform_result()
  end

  defp perform_request(json_body, source_url) do
    case HTTPoison.post(source_url, json_body, headers()) do
      {:ok, r = %Response{body: body, status_code: 200}} ->
        {:ok, Jason.decode!(body, keys: :atoms)}

      e -> e
    end
  end

  defp transform_result({:ok, %{id: id, result: address}}) do
    address
    |> String.slice(-40..-1) #last 40 characters of response
    |> then(&("0x" <> &1))
  end

  def headers do
    [{"Content-Type", "application/json"}]
  end
end
