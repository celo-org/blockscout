defmodule BlockScoutWeb.ValidateRouteParams do
  @moduledoc """
  Validates route parameters

  To trigger validation, a map of keys to validation functions / atoms must be set under the `:validate` key in the
  the private field of the Plug.Conn object. This plug is designed to fail safe, that is - unless a parameter has
  been found to be explicitly invalid it will be treated as invalid.

  Validation functions can be any function that returns a boolean variable, an atom representing any of the kernel
  functions (e.g. :is_integer, :is_float) or :is_address which invokes Explorer.Chain.Hash.Address.validate/1.
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
      |> Enum.any?(fn valid -> valid == false end)

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

  defp is_address(param) do
    case Address.validate(param) do
      {:ok, _} -> true
      _ -> false
    end
  end
end