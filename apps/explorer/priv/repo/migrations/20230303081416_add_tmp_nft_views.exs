defmodule Explorer.Repo.Local.Migrations.AddTmpNftViews do
  use Ecto.Migration

  def up do
    execute("""
    CREATE MATERIALIZED VIEW IF NOT EXISTS tmp_nft_tokens AS SELECT contract_address_hash FROM tokens WHERE tokens.type = 'ERC-721' OR tokens."type" = 'ERC-1155';

    CREATE INDEX contract_address_hash ON tmp_nft_tokens (contract_address_hash);

    CREATE MATERIALIZED VIEW IF NOT EXISTS tmp_nft_token_transfers AS SELECT token_contract_address_hash, token_id, token_ids FROM token_transfers WHERE token_transfers.token_id is not null OR token_transfers.token_ids is not null;

    CREATE INDEX hash_token_id ON tmp_nft_token_transfers (token_contract_address_hash, token_id);
    CREATE INDEX hash_token_ids ON tmp_nft_token_transfers (token_contract_address_hash, token_ids);
    CREATE INDEX token_id ON tmp_nft_token_transfers (token_id);
    CREATE INDEX token_ids ON tmp_nft_token_transfers (token_ids);
    """)
  end

  def down do
    execute("""
    DROP MATERIALIZED VIEW IF EXISTS tmp_nft_tokens;
    DROP MATERIALIZED VIEW IF EXISTS tmp_nft_token_transfers;
    """)
  end
end
