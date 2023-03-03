defmodule Explorer.Chain.TmpNftTokenTransfer do
  @moduledoc """
  Temporary representation of a NFT token transfer
  """

  require Logger

  use Explorer.Schema

  alias Explorer.Chain.{Address, Hash}

  @typedoc """
  * `:token_contract_address_hash` - Address hash foreign key
  * `:token_id` - ID of the token (applicable to ERC-721 tokens)
  * `:token_ids` - IDs of the tokens (applicable to ERC-1155 tokens)
  """

  @type t :: %__MODULE__{
          token_contract_address_hash: Hash.Address.t(),
          token_id: non_neg_integer() | nil,
          token_ids: [non_neg_integer()] | nil
        }

  @primary_key {:address_hash, :string, []}
  schema "tmp_nft_token_transfers" do
    field(:token_id, :decimal)
    field(:token_ids, {:array, :decimal})

    belongs_to(
      :token_contract_address,
      Address,
      foreign_key: :token_contract_address_hash,
      references: :hash,
      type: Hash.Address
    )
  end
end
