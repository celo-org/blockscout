defmodule Explorer.Export.CSV do
  alias Explorer.Repo
  alias Explorer.Chain
  alias Explorer.Chain.Address
  alias NimbleCSV.RFC4180
  alias Explorer.Export.CSV.{TokenTransferExporter,TransactionExporter}

  @transaction_timeout :timer.minutes(5) + :timer.seconds(10)
  @query_timeout :timer.minutes(5)
  @pool_timeout :timer.seconds(20) #how long to wait for connection from pool
  @preload_chunks 500 #how many records to stream from db before resolving associations

  #create a stream that will export data to csv
  def stream(module, address = %Address{}, from, to) do
    query = Repo.stream(module.query(address, from, to), timeout: @query_timeout)
    headers = module.row_names()

    query
    |> Stream.chunk_every(@preload_chunks)
    |> Stream.flat_map(fn chunk ->
      # associations can't be directly preloaded in combination with Repo.stream
      # here we explicitly preload associations for every `@preload_chunks` records
      Repo.preload(chunk, module.associations())
    end)
    |> Stream.map(&(module.transform(&1, address) |> List.flatten()))
    |> then(&( Stream.concat([headers], &1)))
    |> RFC4180.dump_to_stream()
  end

  def export(module, address, from, to, conn = %Plug.Conn{}) do
    Repo.transaction(fn ->
      stream(module, address, from, to)
      |> Enum.reduce(conn, fn v, c ->
         {:ok, conn} = Plug.Conn.chunk(c, v)
         conn
      end)
    end, timeout: @transaction_timeout, pool_timeout: @pool_timeout)
  end

  def export(module, address, from, to, destination) do
    Repo.transaction(fn ->
      stream(module, address, from, to)
      |> Enum.into(destination)
    end, [timeout: @transaction_timeout, pool_timeout: @pool_timeout])
  end

  #helper methods to export stuff directly

  def export_transactions(address, from, to, destination) do
    export(TransactionExporter, address, from, to, destination)
  end
  def export_token_transfers(address, from, to, destination) do
    export(TokenTransferExporter, address, from, to, destination)
  end
end