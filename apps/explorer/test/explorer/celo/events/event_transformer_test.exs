defmodule Explorer.Celo.Events.TransformerTest do
  use Explorer.DataCase, async: true

  alias Explorer.Chain.Log
  alias Explorer.Celo.Events.Transformer

  describe "event transformer" do
    @test_log %Log{
      first_topic: "0x45aac85f38083b18efe2d441a65b9c1ae177c78307cb5a5d4aec8f7dbcaeabfe",
      fourth_topic: nil,
      index: 8,
      second_topic: "0x00000000000000000000000088c1c759600ec3110af043c183a2472ab32d099c",
      third_topic: "0x00000000000000000000000047b2db6af05a55d42ed0f3731735f9479abf0673",
      transaction_hash: %Explorer.Chain.Hash{
        byte_count: 32,
        bytes:
          <<51, 29, 185, 3, 161, 229, 18, 118, 203, 232, 19, 53, 6, 69, 194, 216, 184, 147, 82, 253, 153, 80, 89, 61,
          16, 26, 146, 28, 159, 122, 17, 82>>
      },
      type: nil,
      block_number: 10_913_664,
      data: %Explorer.Chain.Data{
        bytes:
          <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 161, 136, 195, 31, 239, 170, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 18, 8, 108, 209, 196, 23, 97, 135, 112, 147, 87, 144, 173,
          113, 77, 119, 48>>
      },
      block_hash: %Explorer.Chain.Hash{
        byte_count: 32,
        bytes:
          <<39, 45, 177, 52, 77, 35, 177, 94, 225, 112, 13, 8, 78, 175, 197, 158, 167, 36, 208, 58, 41, 172, 144, 114,
          90, 101, 80, 42, 78, 59, 143, 220>>
      },
      address_hash: %Explorer.Chain.Hash{
        byte_count: 20,
        bytes: <<141, 102, 119, 25, 33, 68, 41, 40, 112, 144, 126, 63, 168, 165, 82, 127, 229, 90, 127, 246>>
      }
    }

    test "transforms event parameters" do
      test_abi = """
      {
        "anonymous": false,
        "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "account",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "group",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "value",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "units",
          "type": "uint256"
        }
        ],
        "name": "ValidatorGroupVoteActivated",
        "type": "event"
      }
      """

      result = Transformer.decode(test_abi, @test_log)

      assert Enum.all?([:account, :group, :value, :units], &(Map.has_key?(result, &1)))
    end
  end
end