defmodule BlockScoutWeb.API.RPC.EpochControllerTest do
  use BlockScoutWeb.ConnCase

  import Explorer.Factory

  alias Explorer.Chain.{Address, Block, CeloAccountEpoch, CeloElectionRewards, Wei}

  describe "getvoterrewards" do
    test "with missing voter address", %{conn: conn} do
      response =
        conn
        |> get("/api", %{"module" => "epoch", "action" => "getvoterrewards"})
        |> json_response(200)

      assert response["message"] =~ "'voterAddress' is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with an invalid voter address hash", %{conn: conn} do
      response =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "bad_hash"
        })
        |> json_response(200)

      assert response["message"] =~ "One or more voter addresses are invalid"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with an invalid group address hash", %{conn: conn} do
      response =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "0x0000000000000000000000000000000000000001",
          "groupAddress" => "0xinvalid"
        })
        |> json_response(200)

      assert response["message"] =~ "One or more group addresses are invalid"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with an invalid voter address hash in the list", %{conn: conn} do
      response =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "0x0000000000000000000000000000000000000001, bad_hash"
        })
        |> json_response(200)

      assert response["message"] == "One or more voter addresses are invalid"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with an invalid group address hash in the list", %{conn: conn} do
      response =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "0x0000000000000000000000000000000000000001",
          "groupAddress" => "0x0000000000000000000000000000000000000002,0xinvalid"
        })
        |> json_response(200)

      assert response["message"] == "One or more group addresses are invalid"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with an address that doesn't exist, but there is valid data for other address", %{conn: conn} do
      # Make sure that there's data available for other address
      %Address{hash: voter_hash} = insert(:address)
      %Address{hash: group_hash} = insert(:address)

      %Block{hash: block_hash, number: block_number, timestamp: block_timestamp} =
        insert(
          :block,
          number: 17280 * 902,
          timestamp: ~U[2022-01-05T17:42:43.162804Z]
        )

      insert(
        :celo_account_epoch,
        account_hash: voter_hash,
        block_hash: block_hash,
        block_number: block_number
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_hash,
        amount: 8_943_276_509_843_275_698_432_756,
        associated_account_hash: group_hash,
        block_number: block_number,
        block_timestamp: block_timestamp
      )

      expected_result = %{
        "rewards" => [],
        "total" => %{
          "celo" => "0",
          "wei" => "0"
        },
        "from" => "2022-01-03 00:00:00.000000Z",
        "to" => "2022-01-06 00:00:00.000000Z"
      }

      response =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "0x0000000000000000000000000000000000000002",
          "from" => "2022-01-03T00:00:00.000000Z",
          "to" => "2022-01-06T00:00:00.000000Z"
        })
        |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with valid voter addresses", %{conn: conn} do
      wei_per_ether = 1_000_000_000_000_000_000

      %Address{hash: voter_1_hash} = insert(:address)
      %Address{hash: voter_2_hash} = insert(:address)
      %Address{hash: group_1_hash} = insert(:address)
      %Address{hash: group_2_hash} = insert(:address)

      # TODO maybe not needed after changing the FK
      insert(:celo_account, address: group_1_hash)
      insert(:celo_account, address: group_2_hash)

      block_1 =
        insert(
          :block,
          number: 17280 * 902,
          timestamp: ~U[2022-01-01T17:42:43.162804Z]
        )

      block_2 =
        insert(
          :block,
          number: 17280 * 903,
          timestamp: ~U[2022-01-02T17:42:43.162804Z]
        )

      block_3 =
        insert(
          :block,
          number: 17280 * 904,
          timestamp: ~U[2022-01-03T17:42:43.162804Z]
        )

      %CeloAccountEpoch{total_locked_gold: locked_gold_1_1, nonvoting_locked_gold: nonvoting_gold_1_1} =
        insert(
          :celo_account_epoch,
          account_hash: voter_1_hash,
          block_hash: block_1.hash,
          block_number: block_1.number
        )

      %CeloAccountEpoch{total_locked_gold: locked_gold_1_2, nonvoting_locked_gold: nonvoting_gold_1_2} =
        insert(
          :celo_account_epoch,
          account_hash: voter_1_hash,
          block_hash: block_2.hash,
          block_number: block_2.number
        )

      %CeloAccountEpoch{total_locked_gold: locked_gold_1_3, nonvoting_locked_gold: nonvoting_gold_1_3} =
        insert(
          :celo_account_epoch,
          account_hash: voter_1_hash,
          block_hash: block_3.hash,
          block_number: block_3.number
        )

      %CeloAccountEpoch{total_locked_gold: locked_gold_2_1, nonvoting_locked_gold: nonvoting_gold_2_1} =
        insert(
          :celo_account_epoch,
          account_hash: voter_2_hash,
          block_hash: block_1.hash,
          block_number: block_1.number
        )

      %CeloAccountEpoch{total_locked_gold: locked_gold_2_2, nonvoting_locked_gold: nonvoting_gold_2_2} =
        insert(
          :celo_account_epoch,
          account_hash: voter_2_hash,
          block_hash: block_2.hash,
          block_number: block_2.number
        )

      %CeloAccountEpoch{total_locked_gold: locked_gold_2_3, nonvoting_locked_gold: nonvoting_gold_2_3} =
        insert(
          :celo_account_epoch,
          account_hash: voter_2_hash,
          block_hash: block_3.hash,
          block_number: block_3.number
        )

      %CeloElectionRewards{amount: reward_amount_1_1_1} =
        insert(
          :celo_election_rewards,
          account_hash: voter_1_hash,
          associated_account_hash: group_1_hash,
          block_number: block_1.number,
          block_timestamp: block_1.timestamp,
          amount: wei_per_ether * 1,
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_1_1_2} =
        insert(
          :celo_election_rewards,
          account_hash: voter_1_hash,
          associated_account_hash: group_1_hash,
          block_number: block_2.number,
          block_timestamp: block_2.timestamp,
          amount: wei_per_ether * 2,
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_1_1_3} =
        insert(
          :celo_election_rewards,
          account_hash: voter_1_hash,
          associated_account_hash: group_1_hash,
          block_number: block_3.number,
          block_timestamp: block_3.timestamp,
          amount: wei_per_ether * 3,
          reward_type: "voter"
        )

      # Should we add (remove existing?) foreign key celo_election_rewards.associated_account_hash -> addresses.hash?
      %CeloElectionRewards{amount: reward_amount_1_2_1} =
        insert(
          :celo_election_rewards,
          account_hash: voter_1_hash,
          associated_account_hash: group_2_hash,
          block_number: block_1.number,
          block_timestamp: block_1.timestamp,
          amount: wei_per_ether * 4,
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_1_2_2} =
        insert(
          :celo_election_rewards,
          account_hash: voter_1_hash,
          associated_account_hash: group_2_hash,
          block_number: block_2.number,
          block_timestamp: block_2.timestamp,
          amount: wei_per_ether * 5,
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_1_2_3} =
        insert(
          :celo_election_rewards,
          account_hash: voter_1_hash,
          associated_account_hash: group_2_hash,
          block_number: block_3.number,
          block_timestamp: block_3.timestamp,
          amount: wei_per_ether * 6,
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_2_1_1} =
        insert(
          :celo_election_rewards,
          account_hash: voter_2_hash,
          associated_account_hash: group_1_hash,
          block_number: block_1.number,
          block_timestamp: block_1.timestamp,
          amount: wei_per_ether * 7,
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_2_1_2} =
        insert(
          :celo_election_rewards,
          account_hash: voter_2_hash,
          associated_account_hash: group_1_hash,
          block_number: block_2.number,
          block_timestamp: block_2.timestamp,
          amount: wei_per_ether * 8,
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_2_1_3} =
        insert(
          :celo_election_rewards,
          account_hash: voter_2_hash,
          associated_account_hash: group_1_hash,
          block_number: block_3.number,
          block_timestamp: block_3.timestamp,
          amount: wei_per_ether * 9,
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_2_2_1} =
        insert(
          :celo_election_rewards,
          account_hash: voter_2_hash,
          associated_account_hash: group_2_hash,
          block_number: block_1.number,
          block_timestamp: block_1.timestamp,
          amount: wei_per_ether * 10,
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_2_2_2} =
        insert(
          :celo_election_rewards,
          account_hash: voter_2_hash,
          associated_account_hash: group_2_hash,
          block_number: block_2.number,
          block_timestamp: block_2.timestamp,
          amount: wei_per_ether * 11,
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_2_2_3} =
        insert(
          :celo_election_rewards,
          account_hash: voter_2_hash,
          associated_account_hash: group_2_hash,
          block_number: block_3.number,
          block_timestamp: block_3.timestamp,
          amount: wei_per_ether * 12,
          reward_type: "voter"
        )

      # Repetition of the rewards, but with different type (to make sure that filtering by the type just works)
      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_1_hash,
        block_number: block_1.number,
        block_timestamp: block_1.timestamp,
        amount: wei_per_ether * 7,
        reward_type: "validator"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_1_hash,
        block_number: block_2.number,
        block_timestamp: block_2.timestamp,
        amount: wei_per_ether * 8,
        reward_type: "validator"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_1_hash,
        block_number: block_3.number,
        block_timestamp: block_3.timestamp,
        amount: wei_per_ether * 9,
        reward_type: "validator"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_2_hash,
        block_number: block_1.number,
        block_timestamp: block_1.timestamp,
        amount: wei_per_ether * 10,
        reward_type: "validator"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_2_hash,
        block_number: block_2.number,
        block_timestamp: block_2.timestamp,
        amount: wei_per_ether * 11,
        reward_type: "validator"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_2_hash,
        block_number: block_3.number,
        block_timestamp: block_3.timestamp,
        amount: wei_per_ether * 12,
        reward_type: "validator"
      )

      # Rewards for block 3 should be excluded
      total_rewards =
        reward_amount_2_1_1
        |> Wei.sum(reward_amount_2_1_2)
        |> Wei.sum(reward_amount_2_2_1)
        |> Wei.sum(reward_amount_2_2_2)

      expected_result_first_page = %{
        "rewards" =>
          [
            {block_2, voter_2_hash, group_1_hash, reward_amount_2_1_2, locked_gold_2_2, nonvoting_gold_2_2},
            {block_2, voter_2_hash, group_2_hash, reward_amount_2_2_2, locked_gold_2_2, nonvoting_gold_2_2},
            {block_1, voter_2_hash, group_1_hash, reward_amount_2_1_1, locked_gold_2_1, nonvoting_gold_2_1}
          ]
          |> Enum.map(&map_tuple_to_api_item/1),
        "total" => %{
          "celo" => to_string(Wei.to(total_rewards, :ether)),
          "wei" => to_string(total_rewards)
        },
        "from" => "2022-01-01T00:00:00.000000Z",
        "to" => "2022-01-02T23:59:00.000000Z"
      }

      response_first_page =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => to_string(voter_2_hash),
          "page_size" => "3",
          "from" => "2022-01-01T00:00:00.000000Z",
          "to" => "2022-01-02T23:59:00.000000Z"
        })
        |> json_response(200)

      assert response_first_page["result"] == expected_result_first_page
      assert response_first_page["status"] == "1"
      assert response_first_page["message"] == "OK"
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response_first_page)

      expected_result_second_page = %{
        "rewards" =>
          [
            {block_1, voter_2_hash, group_2_hash, reward_amount_2_2_1, locked_gold_2_1, nonvoting_gold_2_1}
          ]
          |> Enum.map(&map_tuple_to_api_item/1),
        "total" => %{
          "celo" => to_string(Wei.to(total_rewards, :ether)),
          "wei" => to_string(total_rewards)
        },
        "from" => "2022-01-01T00:00:00.000000Z",
        "to" => "2022-01-02T23:59:00.000000Z"
      }

      response_second_page =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => to_string(voter_2_hash),
          "page_size" => "3",
          "items_count" => "3",
          "from" => "2022-01-01T00:00:00.000000Z",
          "to" => "2022-01-02T23:59:00.000000Z"
        })
        |> json_response(200)

      assert response_second_page["result"] == expected_result_second_page
      assert response_second_page["status"] == "1"
      assert response_second_page["message"] == "OK"
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response_second_page)

      total_rewards_single_group_multiple_voters =
        reward_amount_1_2_3
        |> Wei.sum(reward_amount_2_2_3)

      expected_result_single_group_multiple_voters = %{
        "rewards" =>
          [
            {block_3, voter_1_hash, group_2_hash, reward_amount_1_2_3, locked_gold_1_3, nonvoting_gold_1_3},
            {block_3, voter_2_hash, group_2_hash, reward_amount_2_2_3, locked_gold_2_3, nonvoting_gold_2_3}
          ]
          |> Enum.map(&map_tuple_to_api_item/1),
        "total" => %{
          "celo" => to_string(Wei.to(total_rewards_single_group_multiple_voters, :ether)),
          "wei" => to_string(total_rewards_single_group_multiple_voters)
        },
        "from" => "2022-01-03T00:00:00.000000Z",
        "to" => "2022-01-04T00:00:00.000000Z"
      }

      response_single_group_multiple_voters =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "#{to_string(voter_2_hash)},#{to_string(voter_1_hash)}",
          "groupAddress" => to_string(group_2_hash),
          "from" => "2022-01-03T00:00:00.000000Z",
          "to" => "2022-01-04T00:00:00.000000Z"
        })
        |> json_response(200)

      assert response_single_group_multiple_voters["result"] == expected_result_single_group_multiple_voters
      assert response_single_group_multiple_voters["status"] == "1"
      assert response_single_group_multiple_voters["message"] == "OK"
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response_single_group_multiple_voters)
    end
  end

  defp map_tuple_to_api_item({block, voter_hash, group_hash, reward_amount, locked_gold, nonvoting_locked_gold}) do
    activated_gold = locked_gold |> Wei.sub(nonvoting_locked_gold)

    %{
      "amount" => %{"celo" => to_string(reward_amount |> Wei.to(:ether)), "wei" => to_string(reward_amount)},
      "blockHash" => to_string(block.hash),
      "blockNumber" => to_string(block.number),
      "date" => block.timestamp |> DateTime.to_iso8601(),
      "epochNumber" => to_string(div(block.number, 17280)),
      "groupAddress" => to_string(group_hash),
      "voterActivatedGold" => %{
        "celo" => to_string(activated_gold |> Wei.to(:ether)),
        "wei" => to_string(activated_gold)
      },
      "voterAddress" => to_string(voter_hash),
      "voterLockedGold" => %{
        "celo" => to_string(locked_gold |> Wei.to(:ether)),
        "wei" => to_string(locked_gold)
      }
    }
  end

  defp generic_rewards_schema do
    resolve_schema(%{
      "type" => "object",
      "required" => ["total", "from", "to", "rewards"],
      "properties" => %{
        "total" => %{
          "type" => "object",
          "required" => ["celo", "wei"],
          "properties" => %{
            "celo" => %{"type" => "string"},
            "wei" => %{"type" => "string"}
          }
        },
        "from" => %{"type" => "string"},
        "to" => %{"type" => "string"},
        "rewards" => generic_epoch_rewards_schema()
      }
    })
  end

  defp generic_epoch_rewards_schema do
    %{
      "type" => "array",
      "items" => %{
        "type" => "object",
        "required" => [
          "blockHash",
          "blockNumber",
          "epochNumber",
          "voterAddress",
          "voterLockedGold",
          "voterActivatedGold",
          "groupAddress",
          "date",
          "amount"
        ],
        "properties" => %{
          "blockHash" => %{"type" => "string"},
          "blockNumber" => %{"type" => "string"},
          "epochNumber" => %{"type" => "string"},
          "voterAddress" => %{"type" => "string"},
          "voterLockedGold" => %{
            "type" => "object",
            "required" => ["celo", "wei"],
            "properties" => %{
              "celo" => %{"type" => "string"},
              "wei" => %{"type" => "string"}
            }
          },
          "voterActivatedGold" => %{
            "type" => "object",
            "required" => ["celo", "wei"],
            "properties" => %{
              "celo" => %{"type" => "string"},
              "wei" => %{"type" => "string"}
            }
          },
          "groupAddress" => %{"type" => "string"},
          "date" => %{"type" => "string"},
          "amount" => %{
            "type" => "object",
            "required" => ["celo", "wei"],
            "properties" => %{
              "celo" => %{"type" => "string"},
              "wei" => %{"type" => "string"}
            }
          }
        }
      }
    }
  end

  defp resolve_schema(result) do
    %{
      "type" => "object",
      "properties" => %{
        "message" => %{"type" => "string"},
        "status" => %{"type" => "string"}
      }
    }
    |> put_in(["properties", "result"], result)
    |> ExJsonSchema.Schema.resolve()
  end
end
