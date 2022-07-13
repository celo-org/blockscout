defmodule Explorer.Chain.CeloAccountEpoch do
  @moduledoc """
  Datatype for storing Celo epoch data per account
  """

  require Logger

  use Explorer.Schema

  import Ecto.Query,
    only: [
      from: 2
    ]

  alias Explorer.Chain.{Block, Hash, Wei, Address}
  alias Explorer.Repo

  @typedoc """
  * `block_hash` - block where this reward was paid.
  """

  @type t :: %__MODULE__{
          account_hash: Hash.Full.t(),
          block_hash: Hash.Full.t(),
          locked_gold: Wei.t()
        }

  @attrs ~w( account_hash block_hash locked_gold )a

  @required_attrs ~w( account_hash block_hash )a

  schema "celo_account_epoch" do
    field(:locked_gold, Wei)
    field(:activated_gold, Wei)

    belongs_to(:block, Block,
      foreign_key: :block_hash,
      primary_key: true,
      references: :hash,
      type: Hash.Full
    )

    belongs_to(:account, Address.Hash,
      foreign_key: :account_hash,
      primary_key: true,
      references: :hash,
      type: Hash.Full
    )

    timestamps(null: false, type: :utc_datetime_usec)
  end

  def changeset(%__MODULE__{} = item, attrs) do
    item
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)

    # TODO what is this for?
    # |> unique_constraint(:celo_epoch_rewards_key, name: :celo_epoch_rewards_block_hash_index)
  end

  # def get_celo_epoch_rewards_for_block(block_number) do
  #   Repo.one(from(rewards in __MODULE__, where: rewards.block_number == ^block_number))
  # end
end
