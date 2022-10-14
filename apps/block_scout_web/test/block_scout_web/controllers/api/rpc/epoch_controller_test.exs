defmodule BlockScoutWeb.API.RPC.EpochControllerTest do
  use BlockScoutWeb.ConnCase

  import Explorer.Factory

  alias Explorer.Chain.{Address, Block, CeloAccount}

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

    test "with an address that doesn't exist", %{conn: conn} do
      expected_result = %{
        "rewards" => [],
        "totalRewardCelo" => "0",
        "from" => "2022-01-03 00:00:00.000000Z",
        "to" => "2022-01-06 00:00:00.000000Z"
      }

      response =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b",
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

    test "with valid voter hash", %{conn: conn} do
      %Address{hash: voter_hash} = insert(:address)
      %Address{hash: group_hash} = insert(:address)
      %CeloAccount{name: group_name} = insert(:celo_account, address: group_hash)

      %Block{number: block_1_number, timestamp: block_1_timestamp} =
        insert(:block, number: 17_280, timestamp: ~U[2022-01-05T17:42:43.162804Z])

      %Block{number: block_2_number, timestamp: block_2_timestamp} =
        insert(:block, number: 17_280 * 2, timestamp: ~U[2022-01-06T17:42:43.162804Z])

      insert(
        :celo_election_rewards,
        account_hash: voter_hash,
        amount: 80,
        associated_account_hash: group_hash,
        block_number: block_1_number,
        block_timestamp: block_1_timestamp
      )

      insert(
        :celo_election_rewards,
        account_hash: voter_hash,
        amount: 20,
        associated_account_hash: group_hash,
        block_number: block_2_number,
        block_timestamp: block_2_timestamp
      )

      expected_result = %{
        "rewards" => [
          %{
            "account" => to_string(voter_hash),
            "amount" => "80",
            "date" => "2022-01-05T17:42:43.162804Z",
            "blockNumber" => "17280",
            "epochNumber" => "1",
            "group" => group_name
          }
        ],
        "totalRewardCelo" => "80",
        "from" => "2022-01-03 00:00:00.000000Z",
        "to" => "2022-01-06 00:00:00.000000Z"
      }

      response =
        conn
        |> get("/api", %{
          "module" => "epoch",
          "action" => "getvoterrewards",
          "voterAddress" => to_string(voter_hash),
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
  end

  defp generic_rewards_schema do
    resolve_schema(%{
      "type" => ["object", "null"],
      "properties" => %{
        "total_reward_celo" => %{"type" => "string"},
        "account" => %{"type" => "string"},
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
        "properties" => %{
          "amount" => %{"type" => "string"},
          "block_hash" => %{"type" => "string"},
          "block_number" => %{"type" => "string"},
          "date" => %{"type" => "string"},
          "epoch_number" => %{"type" => "string"},
          "group" => %{"type" => "string"}
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
