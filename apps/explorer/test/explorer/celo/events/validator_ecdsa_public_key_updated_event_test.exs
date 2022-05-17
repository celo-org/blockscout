defmodule Explorer.Celo.Events.ValidatorEcdsaPublicKeyUpdatedEvent do
  use Explorer.DataCase, async: true

  alias Explorer.Chain.CeloContractEvent
  alias Explorer.Chain.{Address, Block, Log}
  alias Explorer.Celo.ContractEvents.EventTransformer
  alias Explorer.Celo.ContractEvents.EventMap
  alias Explorer.Celo.ContractEvents.Validators.ValidatorEcdsaPublicKeyUpdatedEvent

  describe "encoding / decoding" do
    test "should handle encoding of bytes data that includes invalid utf8 codepoints" do

      %Explorer.Chain.Block{number: block_number} = insert(:block)
      %Explorer.Chain.CeloCoreContract{address_hash: address_hash} = insert(:core_contract)

      # values taken from production environment and causing an error due to "invalid byte 0x95" in ecdsa_public_key
      contract_event = %CeloContractEvent{
        block_number: block_number,
        contract_address_hash:  address_hash,
        inserted_at: ~U[2022-05-16 13:11:06.729479Z],
        log_index: 12,
        name: "ValidatorEcdsaPublicKeyUpdated",
        params: %{
          ecdsa_public_key:
            <<27, 149, 173, 3, 199, 243, 248, 121, 204, 177, 130, 75, 29, 132, 235, 113, 78, 246, 213, 171, 152, 216,
            246, 254, 154, 199, 124, 145, 7, 153, 92, 105, 76, 239, 244, 76, 75, 6, 166, 156, 19, 179, 255, 236, 186,
            85, 16, 198, 10, 147, 57, 94, 183, 88, 171, 28, 12, 210, 179, 85, 248, 221, 82, 36>>,
          validator: "\\x2bdc5ccda08a7f821ae0df72b5fda60cd58d6353"
        },
        topic: "0x213377eec2c15b21fa7abcbb0cb87a67e893cdb94a2564aa4bb4d380869473c8",
        transaction_hash: nil,
        updated_at: ~U[2022-05-16 13:11:06.729479Z]
      }

      changeset_params = EventMap.celo_contract_event_to_concrete_event(contract_event)
      |> EventMap.event_to_contract_event_params()

      {1, _} = Explorer.Repo.insert_all(CeloContractEvent, [changeset_params])
    end
  end
end
