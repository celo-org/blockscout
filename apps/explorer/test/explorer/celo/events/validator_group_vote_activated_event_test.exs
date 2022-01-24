"""
[
  %Explorer.Chain.Log{
    __meta__: #Ecto.Schema.Metadata<:loaded, "logs">,
    address: #Ecto.Association.NotLoaded<association :address is not loaded>,
    address_hash: %Explorer.Chain.Hash{
      byte_count: 20,
      bytes: <<141, 102, 119, 25, 33, 68, 41, 40, 112, 144, 126, 63, 168, 165,
        82, 127, 229, 90, 127, 246>>
    },
    block: #Ecto.Association.NotLoaded<association :block is not loaded>,
    block_hash: %Explorer.Chain.Hash{
      byte_count: 32,
      bytes: <<73, 198, 72, 89, 132, 87, 138, 220, 58, 49, 180, 49, 98, 150,
        160, 223, 147, 163, 210, 52, 97, 156, 175, 160, 51, 41, 52, 88, 62, 156,
        165, 175>>
    },
    block_number: 10914262,
    data: %Explorer.Chain.Data{
      bytes: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 15, 32, 117, 57, 149, 45, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 75, 33, 211, 233, 85, 104, 70, 134, 95, 73, 21, 34, 179,
        216, 64, 249>>
    },
    first_topic: "0x45aac85f38083b18efe2d441a65b9c1ae177c78307cb5a5d4aec8f7dbcaeabfe",
    fourth_topic: nil,
    index: 5,
    inserted_at: ~U[2022-01-14 08:41:14.816634Z],
    second_topic: "0x00000000000000000000000099fa5f8cfbd887587392b3392452d42037e62ce8",
    third_topic: "0x000000000000000000000000dadbd6cfb29b054adc9c4c2ef0f21f0bbdb44871",
    transaction: #Ecto.Association.NotLoaded<association :transaction is not loaded>,
    transaction_hash: %Explorer.Chain.Hash{
      byte_count: 32,
      bytes: <<149, 97, 42, 163, 148, 130, 135, 86, 216, 129, 238, 30, 148, 160,
        19, 139, 120, 64, 82, 35, 220, 136, 201, 58, 4, 35, 134, 237, 131, 63,
        20, 118>>
    },
    type: nil,
    updated_at: ~U[2022-01-14 08:41:14.816634Z]
  },
  %Explorer.Chain.Log{
    __meta__: #Ecto.Schema.Metadata<:loaded, "logs">,
    address: #Ecto.Association.NotLoaded<association :address is not loaded>,
    address_hash: %Explorer.Chain.Hash{
      byte_count: 20,
      bytes: <<141, 102, 119, 25, 33, 68, 41, 40, 112, 144, 126, 63, 168, 165,
        82, 127, 229, 90, 127, 246>>
    },
    block: #Ecto.Association.NotLoaded<association :block is not loaded>,
    block_hash: %Explorer.Chain.Hash{
      byte_count: 32,
      bytes: <<39, 45, 177, 52, 77, 35, 177, 94, 225, 112, 13, 8, 78, 175, 197,
        158, 167, 36, 208, 58, 41, 172, 144, 114, 90, 101, 80, 42, 78, 59, 143,
        220>>
    },
    block_number: 10913664,
    data: %Explorer.Chain.Data{
      bytes: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 3, 161, 136, 195, 31, 239, 170, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 18, 8, 108, 209, 196, 23, 97, 135, 112, 147, 87, 144,
        173, 113, 77, 119, 48>>
    },
    first_topic: "0x45aac85f38083b18efe2d441a65b9c1ae177c78307cb5a5d4aec8f7dbcaeabfe",
    fourth_topic: nil,
    index: 8,
    inserted_at: ~U[2022-01-14 07:51:25.315238Z],
    second_topic: "0x00000000000000000000000088c1c759600ec3110af043c183a2472ab32d099c",
    third_topic: "0x00000000000000000000000047b2db6af05a55d42ed0f3731735f9479abf0673",
    transaction: #Ecto.Association.NotLoaded<association :transaction is not loaded>,
    transaction_hash: %Explorer.Chain.Hash{
      byte_count: 32,
      bytes: <<51, 29, 185, 3, 161, 229, 18, 118, 203, 232, 19, 53, 6, 69, 194,
        216, 184, 147, 82, 253, 153, 80, 89, 61, 16, 26, 146, 28, 159, 122, 17,
        82>>
    },
    type: nil,
    updated_at: ~U[2022-01-14 07:51:25.315238Z]
  }
]
"""


defmodule Explorer.Celo.Events.ValidatorGroupVoteActivatedEventTest do
  use ExUnit.Case

  alias Explorer.Chain.Log
  alias Explorer.Celo.ContractEvents.EventTransformer
  alias Explorer.Celo.ContractEvents.Election.ValidatorGroupVoteActivatedEvent
  describe "Test conversion" do
    test "converts from db log to concrete event type" do
      test_log = %Log{
        first_topic: "0x45aac85f38083b18efe2d441a65b9c1ae177c78307cb5a5d4aec8f7dbcaeabfe",
        fourth_topic: nil,
        index: 8,
        second_topic: "0x00000000000000000000000088c1c759600ec3110af043c183a2472ab32d099c",
        third_topic: "0x00000000000000000000000047b2db6af05a55d42ed0f3731735f9479abf0673",
        transaction_hash: %Explorer.Chain.Hash{
          byte_count: 32,
          bytes: <<51, 29, 185, 3, 161, 229, 18, 118, 203, 232, 19, 53, 6, 69, 194,
            216, 184, 147, 82, 253, 153, 80, 89, 61, 16, 26, 146, 28, 159, 122, 17,
            82>>
        },
        type: nil,
        block_number: 10913664,
        data: %Explorer.Chain.Data{
          bytes: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 3, 161, 136, 195, 31, 239, 170, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 18, 8, 108, 209, 196, 23, 97, 135, 112, 147, 87, 144,
            173, 113, 77, 119, 48>>
        },
        block_hash: %Explorer.Chain.Hash{
          byte_count: 32,
          bytes: <<39, 45, 177, 52, 77, 35, 177, 94, 225, 112, 13, 8, 78, 175, 197,
            158, 167, 36, 208, 58, 41, 172, 144, 114, 90, 101, 80, 42, 78, 59, 143,
            220>>
        },
        address_hash: %Explorer.Chain.Hash{
          byte_count: 20,
          bytes: <<141, 102, 119, 25, 33, 68, 41, 40, 112, 144, 126, 63, 168, 165,
            82, 127, 229, 90, 127, 246>>
        }
      }

      result = ValidatorGroupVoteActivatedEvent |> EventTransformer.from_log(test_log)

    end
  end
end