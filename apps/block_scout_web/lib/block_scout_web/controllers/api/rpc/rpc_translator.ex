defmodule BlockScoutWeb.API.RPC.RPCTranslator do
  @moduledoc """
  Converts an RPC-style request into a controller action.

  Requests are expected to have URL query params like `?module=module&action=action`.

  ## Configuration

  The plugs needs a map relating a `module` string to a controller module.

      # In a router
      forward "/api", RPCTranslator, %{"block" => BlockController}

  """

  require Logger

  import Plug.Conn
  import Phoenix.Controller, only: [put_view: 2]

  alias BlockScoutWeb.AccessHelpers
  alias BlockScoutWeb.API.APILogger
  alias BlockScoutWeb.API.RPC.RPCView
  alias Phoenix.Controller
  alias Plug.Conn

  def init(opts) do
    ensure_rpc_modules_loaded()
    opts
  end

  defp ensure_rpc_modules_loaded do
    modules = Application.get_env(:block_scout_web, :rpc_module_map)

    modules
    |> Enum.each(fn {_key, {module, _params}} ->
      Code.ensure_loaded!(module)
    end)
  end

  def call(%Conn{params: %{"module" => module, "action" => action}} = conn, translations) do
    with :valid <- valid_api_request_path(conn),
         {:ok, {controller, write_actions}} <- translate_module(translations, module),
         {:ok, action} <- translate_action(action),
         true <- action_accessed?(action, write_actions),
         :ok <- AccessHelpers.check_rate_limit(conn),
         {:ok, conn} <- call_controller(conn, controller, action) do
      APILogger.log(conn)
      conn
    else
      {:error, :no_action} ->
        conn
        |> put_status(400)
        |> put_view(RPCView)
        |> Controller.render(:error, error: "Unknown action")
        |> halt()

      {:error, error} ->
        Logger.error(fn -> ["Error while calling RPC action", inspect(error)] end)

        conn
        |> put_status(500)
        |> put_view(RPCView)
        |> Controller.render(:error, error: "Something went wrong.")
        |> halt()

      :rate_limit_reached ->
        AccessHelpers.handle_rate_limit_deny(conn)

      :invalid ->
        conn
        |> put_status(404)
        |> put_view(RPCView)
        |> Controller.render(:error, error: "Request path not found.")
        |> halt()

      _ ->
        conn
        |> put_status(500)
        |> put_view(RPCView)
        |> Controller.render(:error, error: "Something went wrong.")
        |> halt()
    end
  end

  def call(%Conn{} = conn, _) do
    conn
    |> put_status(400)
    |> put_view(RPCView)
    |> Controller.render(:error, error: "Params 'module' and 'action' are required parameters")
    |> halt()
  end

  @doc false
  @spec translate_module(map(), String.t()) :: {:ok, {module(), list(atom())}} | {:error, :no_action}
  defp translate_module(translations, module) do
    module_lowercase = String.downcase(module)

    case Map.fetch(translations, module_lowercase) do
      {:ok, module} ->
        {:ok, module}

      _ ->
        {:error, :no_action}
    end
  end

  @doc false
  @spec translate_action(String.t()) :: {:ok, atom()} | {:error, :no_action}
  defp translate_action(action) do
    action_lowercase = String.downcase(action)
    {:ok, String.to_existing_atom(action_lowercase)}
  rescue
    e ->
      {:error, :no_action}
  end

  defp action_accessed?(_action, _write_actions) do
    conf = Application.get_env(:block_scout_web, BlockScoutWeb.ApiRouter)

    if conf[:writing_enabled] do
      true
    else
      {:error, :no_action}
    end
  end

  @doc false
  @spec call_controller(Conn.t(), module(), atom()) :: {:ok, Conn.t()} | {:error, :no_action} | {:error, Exception.t()}
  defp call_controller(conn, controller, action) do
    if :erlang.function_exported(controller, action, 2) do
      {:ok, controller.call(conn, action)}
    else
      {:error, :no_action}
    end
  rescue
    e ->
      {:error, Exception.format(:error, e, __STACKTRACE__)}
  end

  defp valid_api_request_path(%{request_path: rp}) when rp in ["/api", "/api/", "/api/v1"], do: :valid
  defp valid_api_request_path(_), do: :invalid
end
