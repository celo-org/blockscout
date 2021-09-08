defmodule BlockScoutWeb.ValidateRouteParams do
  @moduledoc """
  Validates route parameters
  """

  import Plug.Conn

  import Phoenix.Controller, only: [not_found: 1]
  alias Explorer.Chain.Hash.Address

  def init(opts), do: opts

  def call(conn = %{params: params, private: %{validate: validation}}, _) do
    validate(conn, params, validation)
  end

  def validate(conn, %{}, _validation), do: conn
  def validate(conn, params, validation) when is_map(validation) do
    invalid =
      validation
      |> Enum.reduce( fn {param, validate_func} ->
       perform_validation(params[param], validate_func)
      end)
      |> Enum.any?(fn result -> result == false end)

   if invalid do
     conn
     |> not_found()
     |> halt()
   else
    conn
   end
  end
  def validate(conn, _, _), do: conn

  def perform_validation(p, validator) when is_function(validator), do: validator(p)
  def perform_validation(p, validator) when is_atom(validator), do: apply(__MODULE__, validator, [1, p])
  def perform_validation(nil, validator), do: true

  def call(conn, _) do
    IO.inspect(conn)
    conn
  end

  defp is_address?(param) do
    case Address.validate(param) do
      {:ok, _} -> true
      _ -> false
    end
  end
end