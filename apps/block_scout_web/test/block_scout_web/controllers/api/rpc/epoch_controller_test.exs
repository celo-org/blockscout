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

    test "with an invalid 'from' param", %{conn: conn} do
      response =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "0x0000000000000000000000000000000000000001",
          "from" => "invalid"
        })
        |> json_response(200)

      assert response["message"] =~ "Wrong format for block number provided"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with an invalid 'to' param", %{conn: conn} do
      response =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "0x0000000000000000000000000000000000000001",
          "to" => "invalid"
        })
        |> json_response(200)

      assert response["message"] =~ "Wrong format for block number provided"
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

    test "with provided only 'to' parameter", %{conn: conn} do
      %Block{hash: block_hash, number: block_number} =
        insert(
          :block,
          number: 17280 * 902,
          timestamp: ~U[2022-10-12T18:53:12.162804Z]
        )

      insert(
        :celo_epoch_rewards,
        block_number: block_number,
        block_hash: block_hash
      )

      expected_result = %{
        "rewards" => [],
        "totalAmount" => %{
          "celo" => "0",
          "wei" => "0"
        },
        "totalCount" => "0",
        "from" => "17280",
        "to" => "#{block_number}"
      }

      response =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "0x0000000000000000000000000000000000000002",
          "to" => "#{block_number + 17279}"
        })
        |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with provided only 'from' parameter", %{conn: conn} do
      %Block{hash: block_hash, number: block_number} =
        insert(
          :block,
          number: 17280 * 902,
          timestamp: ~U[2022-10-12T18:53:12.162804Z]
        )

      insert(
        :celo_epoch_rewards,
        block_number: block_number,
        block_hash: block_hash
      )

      expected_result = %{
        "rewards" => [],
        "totalAmount" => %{
          "celo" => "0",
          "wei" => "0"
        },
        "totalCount" => "0",
        "from" => "123465600",
        "to" => "#{block_number}"
      }

      response =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "0x0000000000000000000000000000000000000002",
          "from" => "123456789"
        })
        |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
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
          timestamp: ~U[2022-10-12T18:53:12.162804Z]
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
        block_timestamp: block_timestamp,
        block_hash: block_hash
      )

      insert(
        :celo_epoch_rewards,
        block_number: block_number,
        block_hash: block_hash
      )

      expected_result = %{
        "rewards" => [],
        "totalAmount" => %{
          "celo" => "0",
          "wei" => "0"
        },
        "totalCount" => "0",
        "from" => "17280",
        "to" => "#{block_number}"
      }

      response =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "0x0000000000000000000000000000000000000002"
        })
        |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with valid voter addresses", %{conn: conn} do
      max_reward_base = 1_000_000_000_000_000_000

      %Address{hash: voter_1_hash} = insert(:address)
      %Address{hash: voter_2_hash} = insert(:address)
      %Address{hash: group_1_hash} = insert(:address)
      %Address{hash: group_2_hash} = insert(:address)

      block_1 =
        insert(
          :block,
          number: 17280 * 902,
          timestamp: ~U[2022-10-12T18:53:12.162804Z]
        )

      block_2 =
        insert(
          :block,
          number: 17280 * 903,
          timestamp: ~U[2022-10-13T18:53:12.162804Z]
        )

      block_3 =
        insert(
          :block,
          number: 17280 * 904,
          timestamp: ~U[2022-10-14T18:53:12.162804Z]
        )

      insert(
        :celo_account_epoch,
        account_hash: voter_1_hash,
        block_hash: block_1.hash,
        block_number: block_1.number
      )

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

      insert(
        :celo_election_rewards,
        account_hash: voter_1_hash,
        associated_account_hash: group_1_hash,
        block_number: block_1.number,
        block_timestamp: block_1.timestamp,
        block_hash: block_1.hash,
        amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 1 * :rand.uniform_real()),
        reward_type: "voter"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_1_hash,
        associated_account_hash: group_1_hash,
        block_number: block_2.number,
        block_timestamp: block_2.timestamp,
        block_hash: block_2.hash,
        amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 2 * :rand.uniform_real()),
        reward_type: "voter"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_1_hash,
        associated_account_hash: group_1_hash,
        block_number: block_3.number,
        block_timestamp: block_3.timestamp,
        block_hash: block_3.hash,
        amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 3 * :rand.uniform_real()),
        reward_type: "voter"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_1_hash,
        associated_account_hash: group_2_hash,
        block_number: block_1.number,
        block_timestamp: block_1.timestamp,
        block_hash: block_1.hash,
        amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 4 * :rand.uniform_real()),
        reward_type: "voter"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_1_hash,
        associated_account_hash: group_2_hash,
        block_number: block_2.number,
        block_timestamp: block_2.timestamp,
        block_hash: block_2.hash,
        amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 5 * :rand.uniform_real()),
        reward_type: "voter"
      )

      %CeloElectionRewards{amount: reward_amount_1_2_3} =
        insert(
          :celo_election_rewards,
          account_hash: voter_1_hash,
          associated_account_hash: group_2_hash,
          block_number: block_3.number,
          block_timestamp: block_3.timestamp,
          block_hash: block_3.hash,
          amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 6 * :rand.uniform_real()),
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_2_1_1} =
        insert(
          :celo_election_rewards,
          account_hash: voter_2_hash,
          associated_account_hash: group_1_hash,
          block_number: block_1.number,
          block_timestamp: block_1.timestamp,
          block_hash: block_1.hash,
          amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 7 * :rand.uniform_real()),
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_2_1_2} =
        insert(
          :celo_election_rewards,
          account_hash: voter_2_hash,
          associated_account_hash: group_1_hash,
          block_number: block_2.number,
          block_timestamp: block_2.timestamp,
          block_hash: block_2.hash,
          amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 8 * :rand.uniform_real()),
          reward_type: "voter"
        )

      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_1_hash,
        block_number: block_3.number,
        block_timestamp: block_3.timestamp,
        block_hash: block_3.hash,
        amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 9 * :rand.uniform_real()),
        reward_type: "voter"
      )

      %CeloElectionRewards{amount: reward_amount_2_2_1} =
        insert(
          :celo_election_rewards,
          account_hash: voter_2_hash,
          associated_account_hash: group_2_hash,
          block_number: block_1.number,
          block_timestamp: block_1.timestamp,
          block_hash: block_1.hash,
          amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 10 * :rand.uniform_real()),
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_2_2_2} =
        insert(
          :celo_election_rewards,
          account_hash: voter_2_hash,
          associated_account_hash: group_2_hash,
          block_number: block_2.number,
          block_timestamp: block_2.timestamp,
          block_hash: block_2.hash,
          amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 11 * :rand.uniform_real()),
          reward_type: "voter"
        )

      %CeloElectionRewards{amount: reward_amount_2_2_3} =
        insert(
          :celo_election_rewards,
          account_hash: voter_2_hash,
          associated_account_hash: group_2_hash,
          block_number: block_3.number,
          block_timestamp: block_3.timestamp,
          block_hash: block_3.hash,
          amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 12 * :rand.uniform_real()),
          reward_type: "voter"
        )

      # Repetition of the rewards, but with different type (to make sure that filtering by the type just works)
      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_1_hash,
        block_number: block_1.number,
        block_timestamp: block_1.timestamp,
        block_hash: block_1.hash,
        amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 7 * :rand.uniform_real()),
        reward_type: "validator"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_1_hash,
        block_number: block_2.number,
        block_timestamp: block_2.timestamp,
        block_hash: block_2.hash,
        amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 8 * :rand.uniform_real()),
        reward_type: "validator"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_1_hash,
        block_number: block_3.number,
        block_timestamp: block_3.timestamp,
        block_hash: block_3.hash,
        amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 9 * :rand.uniform_real()),
        reward_type: "validator"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_2_hash,
        block_number: block_1.number,
        block_timestamp: block_1.timestamp,
        block_hash: block_1.hash,
        amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 10 * :rand.uniform_real()),
        reward_type: "validator"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_2_hash,
        block_number: block_2.number,
        block_timestamp: block_2.timestamp,
        block_hash: block_2.hash,
        amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 11 * :rand.uniform_real()),
        reward_type: "validator"
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_2_hash,
        associated_account_hash: group_2_hash,
        block_number: block_3.number,
        block_timestamp: block_3.timestamp,
        block_hash: block_3.hash,
        amount: round(Enum.random(1_000_000_000_000..max_reward_base) * 12 * :rand.uniform_real()),
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
        "totalAmount" => %{
          "celo" => to_string(Wei.to(total_rewards, :ether)),
          "wei" => to_string(total_rewards)
        },
        "totalCount" => "4",
        "from" => "#{block_1.number}",
        "to" => "#{block_2.number}"
      }

      response_first_page =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => to_string(voter_2_hash),
          "page_size" => "3",
          "from" => "#{block_1.number - 1}",
          "to" => "#{block_2.number + 1}"
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
        "totalAmount" => %{
          "celo" => to_string(Wei.to(total_rewards, :ether)),
          "wei" => to_string(total_rewards)
        },
        "totalCount" => "4",
        "from" => "#{block_1.number}",
        "to" => "#{block_2.number}"
      }

      response_second_page =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => to_string(voter_2_hash),
          "page_number" => "2",
          "page_size" => "3",
          "from" => "#{block_1.number - 1}",
          "to" => "#{block_2.number + 1}"
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
        "totalAmount" => %{
          "celo" => to_string(Wei.to(total_rewards_single_group_multiple_voters, :ether)),
          "wei" => to_string(total_rewards_single_group_multiple_voters)
        },
        "totalCount" => "2",
        "from" => "#{block_3.number}",
        "to" => "#{block_3.number}"
      }

      response_single_group_multiple_voters =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "#{to_string(voter_2_hash)},#{to_string(voter_1_hash)}",
          "groupAddress" => to_string(group_2_hash),
          "from" => "#{block_3.number}",
          "to" => "#{block_3.number}"
        })
        |> json_response(200)

      assert response_single_group_multiple_voters["result"] == expected_result_single_group_multiple_voters
      assert response_single_group_multiple_voters["status"] == "1"
      assert response_single_group_multiple_voters["message"] == "OK"
      schema = generic_rewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response_single_group_multiple_voters)
    end
  end

  defp map_tuple_to_api_item({block, voter_hash, group_hash, reward_amount, locked_gold, nonvoting_locked_gold} = tuple) do
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
      "type" => ["object", "null"],
      "required" => ["totalAmount", "totalCount", "from", "to", "rewards"],
      "properties" => %{
        "totalAmount" => %{
          "type" => "object",
          "required" => ["celo", "wei"],
          "properties" => %{
            "celo" => %{"type" => "string"},
            "wei" => %{"type" => "string"}
          }
        },
        "totalCount" => %{"type" => "string"},
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
