defmodule BlockScoutWeb.Plug.ValidateRouteParametersTest do
  use BlockScoutWeb.ConnCase

  import Plug.Conn
  alias BlockScoutWeb.Plug.ValidateRouteParameters
  alias BlockScoutWeb.Router

  describe "call/2" do
    setup %{conn: conn} do
      conn =
        conn
        |> bypass_through(Router, [:browser])
        |> get("/")

      {:ok, conn: conn}
    end

    test "doesn't invalidate base conn", %{conn: conn} do
      result =
        conn |> ValidateRouteParameters.call(nil)

      refute result.halted
    end

    test "doesn't invalidate when validation set but no matching params", %{conn: conn} do
      result =
        conn
        |> put_private(:validate, %{"test_key" => :validation_func})
        |> ValidateRouteParameters.call(nil)

      refute result.halted
    end

    test "invalidates against function", %{conn: conn} do
      conn_with_validation =
        conn
        |> put_private(:validate, %{"test_key" => &(&1 == "expected_value")})

      failed_conn = %{ conn_with_validation | params: Map.merge(conn_with_validation.params, %{"test_key" => "bad_value"})}
                    |> ValidateRouteParameters.call(nil)

      assert failed_conn.halted

      valid_conn = %{ conn_with_validation | params: Map.merge(conn_with_validation.params, %{"test_key" => "expected_value"})}
                    |> ValidateRouteParameters.call(nil)
      refute valid_conn.halted
    end
  end
end
