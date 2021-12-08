defmodule Explorer.Export.CSV do
  alias Explorer.Repo
  alias Explorer.Chain
  alias Explorer.Chain.Address
  alias NimbleCSV.RFC4180
  alias Explorer.Export.CSV.TransactionExporter

  @timeout :timer.minutes(3)
  @pool_timeout :timer.seconds(20)
  @preload_chunks 500 #how many records to stream from db before resolving associations

  #create a stream that will export data to csv
  def stream(module, address = %Address{}, from, to) do
    query = Repo.stream(module.query(address, from, to))
    headers = module.row_names()

    query
    |> Stream.chunk_every(@preload_chunks)
    |> Stream.flat_map(fn chunk ->
      Repo.preload(chunk, module.associations())
    end)
    |> Stream.map(&(module.transform(&1, address)))
    |> then(&( Stream.concat([headers], &1)))
    |> RFC4180.dump_to_stream()
  end

  #run the stream
  def export(module, address, from, to, conn, func) when is_function(func) do
    Repo.transaction(fn ->
      stream(module, address, from, to)
      |> Enum.reduce(conn, func)
    end, [timeout: @timeout, pool_timeout: @pool_timeout])
  end

  def export(module, address, from, to, destination) do
    Repo.transaction(fn ->
      stream(module, address, from, to)
      |> Enum.into(destination)
    end, [timeout: @timeout, pool_timeout: @pool_timeout])
  end

  #helper methods to export stuff directly

  def export_transactions(address, from, to, conn, func) do
    export(TransactionExporter, address, from, to, conn, func)
  end
end