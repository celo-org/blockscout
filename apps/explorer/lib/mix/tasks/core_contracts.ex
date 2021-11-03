defmodule Mix.Tasks.CoreContracts do
  use Mix.Task

  @moduledoc "Builds core contract cache initial values"
  @shortdoc "Build a core contract address cache for a given blockchain endpoint"
  def run([filename, url]) do
    HTTPoison.start()

    addresses = Explorer.Celo.CoreContracts.full_cache_build(url)
    IO.inspect(addresses)
  end
end