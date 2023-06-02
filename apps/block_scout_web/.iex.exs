alias Explorer.Repo
import Ecto.Query

defmodule SQLHelper do
  def to_string(query), do: Ecto.Adapters.SQL.to_sql(:all, Explorer.Repo, query) |> IO.inspect()
end

defmodule Clabs.Debug do
  def test_bad_graphql do
    {:ok,hsh} = Explorer.Chain.Hash.Address.cast("0x6131a6d616a4be3737b38988847270a64bc10caa")
    Explorer.GraphQL.token_txtransfers_query_for_address(hsh)
  end
end