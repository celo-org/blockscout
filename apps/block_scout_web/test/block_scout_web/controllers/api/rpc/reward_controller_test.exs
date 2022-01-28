defmodule BlockScoutWeb.API.RPC.RewardControllerTest do
  use BlockScoutWeb.ConnCase

  alias Explorer.SetupVoterRewardsTest

  describe "getvoterrewardsforgroup" do
    test "with missing voter address", %{conn: conn} do
      response =
        conn
        |> get("/api", %{"module" => "reward", "action" => "getvoterrewardsforgroup"})
        |> json_response(200)

      assert response["message"] =~ "'voterAddress' is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      schema = voterrewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with missing group address", %{conn: conn} do
      response =
        conn
        |> get("/api", %{
          "module" => "reward",
          "action" => "getvoterrewardsforgroup",
          "voterAddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
        })
        |> json_response(200)

      assert response["message"] =~ "'groupAddress' is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      schema = voterrewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with an invalid voter address hash", %{conn: conn} do
      response =
        conn
        |> get("/api", %{
          "module" => "reward",
          "action" => "getvoterrewardsforgroup",
          "voterAddress" => "bad_hash",
          "groupAddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
        })
        |> json_response(200)

      assert response["message"] =~ "Invalid voter address hash"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      schema = voterrewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with an invalid group address hash", %{conn: conn} do
      response =
        conn
        |> get("/api", %{
          "module" => "reward",
          "action" => "getvoterrewardsforgroup",
          "voterAddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b",
          "groupAddress" => "bad_hash"
        })
        |> json_response(200)

      assert response["message"] =~ "Invalid group address hash"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      schema = voterrewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with an address that doesn't exist", %{conn: conn} do
      response =
        conn
        |> get("/api", %{
          "module" => "reward",
          "action" => "getvoterrewardsforgroup",
          "voterAddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b",
          "groupAddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
        })
        |> json_response(200)

      assert response["message"] =~ "Voter or group address does not exist"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      schema = voterrewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end

    test "with valid voter and group address", %{conn: conn} do
      {voter_address_1_hash, group_address_hash} = SetupVoterRewardsTest.setup()

      expected_result = %{
        "epochs" => [
          %{"amount" => "80", "date" => "2022-01-01T17:42:43.162804Z", "epochNumber" => "619"},
          %{"amount" => "20", "date" => "2022-01-02T17:42:43.162804Z", "epochNumber" => "620"},
          %{"amount" => "75", "date" => "2022-01-03T17:42:43.162804Z", "epochNumber" => "621"},
          %{"amount" => "31", "date" => "2022-01-04T17:42:43.162804Z", "epochNumber" => "622"},
          %{"amount" => "77", "date" => "2022-01-05T17:42:43.162804Z", "epochNumber" => "623"},
          %{"amount" => "67", "date" => "2022-01-06T17:42:43.162804Z", "epochNumber" => "624"}
        ],
        "total" => "350"
      }

      response =
        conn
        |> get("/api", %{
          "module" => "reward",
          "action" => "getvoterrewardsforgroup",
          "voterAddress" => to_string(voter_address_1_hash),
          "groupAddress" => to_string(group_address_hash)
        })
        |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
      schema = voterrewards_schema()
      assert :ok = ExJsonSchema.Validator.validate(schema, response)
    end
  end

  defp voterrewards_schema do
    resolve_schema(%{
      "type" => ["object", "null"],
      "properties" => %{
        "total" => %{"type" => "string"},
        "epochs" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "amount" => %{"type" => "string"},
              "date" => %{"type" => "string"},
              "epoch_number" => %{"type" => "string"}
            }
          }
        }
      }
    })
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
