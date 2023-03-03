defmodule Explorer.Chain.TmpNftToken do
  @moduledoc """
  Temporary representation of a NFT token
  """

  require Logger

  use Explorer.Schema

  @typedoc """
  * `contract_address_hash` - NFT contract address hash
  """

  @type t :: %TmpNftTokenTransfer{
          contract_address_hash: Hash.Address.t()
        }

  @primary_key {:address_hash, :string, []}
  schema "tmp_nft_tokens" do
    belongs_to(
      :contract_address,
      Address,
      foreign_key: :contract_address_hash,
      primary_key: true,
      references: :hash,
      type: Hash.Address
    )
  end
end
