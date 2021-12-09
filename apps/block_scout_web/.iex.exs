alias Explorer.Repo
import Ecto.Query


defmodule CSVTesting do
  def get_address() do
    {:ok, hsh} = Explorer.Chain.Hash.cast(Explorer.Chain.Hash.Address, <<173, 58, 26, 6, 231, 12, 201, 211, 233, 9, 223, 147, 210, 126, 213, 41, 150, 47, 191, 76>> )
    Repo.one(from a in Explorer.Chain.Address, where: a.hash == ^hsh)
  end

  def test_export() do
    addr = get_address()
    Explorer.Export.CSV.export_transactions(addr, "2021-01-01", "2021-12-06", [])
  end

  def test_transfers() do
    addr = get_address()
    Explorer.Export.CSV.export_token_transfers(addr, "2021-01-01", "2021-12-06", [])
  end
end
