defmodule BlockScoutWeb.AddressContractVerificationViaJsonController do
  use BlockScoutWeb, :controller

  alias BlockScoutWeb.API.RPC.ContractController
  alias BlockScoutWeb.Controller
  alias Ecto.Changeset
  alias Explorer.Chain
  alias Explorer.Chain.Events.Publisher, as: EventsPublisher
  alias Explorer.Chain.SmartContract
  alias Explorer.SmartContract.Solidity.PublisherWorker, as: SolidityPublisherWorker
  alias Explorer.ThirdPartyIntegrations.Sourcify

  def new(conn, %{"address_id" => address_hash_string}) do
    address_path =
      conn
      |> address_path(:show, address_hash_string)
      |> Controller.full_path()

    if Chain.smart_contract_fully_verified?(address_hash_string) do
      redirect(conn, to: address_path)
    else
      case Sourcify.check_by_address(address_hash_string) do
        {:ok, _verified_status} ->
          case get_metadata_and_publish(address_hash_string, conn) do
            :update_submitted ->
              conn
              |> put_flash(:info, "Contract submitted for verification")
              |> redirect(to: address_path)

            _ ->
              redirect(conn, to: address_path)
          end

        _ ->
          changeset =
            SmartContract.changeset(
              %SmartContract{address_hash: address_hash_string},
              %{}
            )

          render(conn, "new.html", changeset: changeset, address_hash: address_hash_string)
      end
    end
  end

  def create(
        conn,
        %{
          "smart_contract" => smart_contract,
          "external_libraries" => external_libraries
        }
      ) do
    Que.add(SolidityPublisherWorker, {smart_contract["address_hash"], smart_contract, external_libraries, conn})

    send_resp(conn, 204, "")
  end

  def create(
        conn,
        %{
          "address_hash" => address_hash_string,
          "file" => files
        }
      ) do
    files_array = prepare_files_array(files)

    json_files =
      files_array
      |> Enum.filter(fn file -> file.content_type == "application/json" end)

    json_file = json_files |> Enum.at(0)

    if json_file do
      if Chain.smart_contract_fully_verified?(address_hash_string) do
        EventsPublisher.broadcast(
          prepare_verification_error(
            "This contract is already verified.",
            address_hash_string,
            conn
          ),
          :on_demand
        )
      else
        case Sourcify.check_by_address(address_hash_string) do
          {:ok, _verified_status} ->
            get_metadata_and_publish(address_hash_string, conn)

          _ ->
            verify_and_publish(address_hash_string, files_array, conn)
        end
      end
    else
      EventsPublisher.broadcast(
        prepare_verification_error(
          "Please attach JSON file with metadata of contract's compilation.",
          address_hash_string,
          conn
        ),
        :on_demand
      )
    end

    send_resp(conn, 204, "")
  end

  def create(conn, _params) do
    Que.add(SolidityPublisherWorker, {"", %{}, %{}, conn})

    send_resp(conn, 204, "")
  end

  defp verify_and_publish(address_hash_string, files_array, conn) do
    with {:ok, _verified_status} <- Sourcify.verify(address_hash_string, files_array),
         {:ok, _verified_status} <- Sourcify.check_by_address(address_hash_string) do
      get_metadata_and_publish(address_hash_string, conn)
    else
      {:error, %{"error" => error}} ->
        EventsPublisher.broadcast(
          prepare_verification_error(error, address_hash_string, conn),
          :on_demand
        )
    end
  end

  def get_metadata_and_publish(address_hash_string, nil) do
    case Sourcify.get_metadata(address_hash_string) do
      {:ok, verification_metadata} ->
        process_metadata_and_publish(address_hash_string, verification_metadata, false)

      {:error, %{"error" => error}} ->
        {:error, error: error}

      {:error, :timeout} ->
        {:error, error: :timeout}
    end
  end

  def get_metadata_and_publish(address_hash_string, conn) do
    case Sourcify.get_metadata(address_hash_string) do
      {:ok, verification_metadata} ->
        process_metadata_and_publish(address_hash_string, verification_metadata, false, conn)

      {:error, %{"error" => error}} ->
        EventsPublisher.broadcast(
          prepare_verification_error(error, address_hash_string, conn),
          :on_demand
        )
    end
  end

  defp process_metadata_and_publish(address_hash_string, verification_metadata, is_partial, conn \\ nil) do
    %{
      "params_to_publish" => params_to_publish,
      "abi" => abi,
      "secondary_sources" => secondary_sources,
      "compilation_target_file_path" => compilation_target_file_path
    } = parse_params_from_sourcify(address_hash_string, verification_metadata)

    ContractController.publish(conn, %{
      "addressHash" => address_hash_string,
      "params" => Map.put(params_to_publish, "partially_verified", is_partial),
      "abi" => abi,
      "secondarySources" => secondary_sources,
      "compilationTargetFilePath" => compilation_target_file_path
    })
  end

  def prepare_files_array(files) do
    if is_map(files), do: Enum.map(files, fn {_, file} -> file end), else: []
  end

  defp prepare_verification_error(msg, address_hash_string, conn) do
    [
      {:contract_verification_result,
       {address_hash_string,
        {:error,
         %Changeset{
           action: :insert,
           errors: [
             file: {msg, []}
           ],
           data: %SmartContract{},
           valid?: false
         }}, conn}}
    ]
  end

  def parse_params_from_sourcify(address_hash_string, verification_metadata) do
    [verification_metadata_json] =
      verification_metadata
      |> Enum.filter(&(Map.get(&1, "name") == "metadata.json"))

    full_params_initial = parse_json_from_sourcify_for_insertion(verification_metadata_json)

    verification_metadata_sol =
      verification_metadata
      |> Enum.filter(fn %{"name" => name, "content" => _content} -> name =~ ".sol" end)

    verification_metadata_sol
    |> Enum.reduce(full_params_initial, fn %{"name" => name, "content" => content, "path" => _path} = param,
                                           full_params_acc ->
      compilation_target_file_name = Map.get(full_params_acc, "compilation_target_file_name")

      base_params = %{
        "abi" => Map.get(full_params_acc, "abi"),
        "compilation_target_file_path" => Map.get(full_params_acc, "compilation_target_file_path"),
        "compilation_target_file_name" => compilation_target_file_name
      }

      if file_is_compilation_target(name, compilation_target_file_name) do
        to_publish = extract_primary_source_code(content, Map.get(full_params_acc, "params_to_publish"))
        secondary_sources = Map.get(full_params_acc, "secondary_sources")

        base_params
        |> Map.put("params_to_publish", to_publish)
        |> Map.put("secondary_sources", secondary_sources)
      else
        to_publish = Map.get(full_params_acc, "params_to_publish")

        secondary_sources = [
          prepare_additional_source(address_hash_string, param) | Map.get(full_params_acc, "secondary_sources")
        ]

        base_params
        |> Map.put("params_to_publish", to_publish)
        |> Map.put("secondary_sources", secondary_sources)
      end
    end)
  end

  defp file_is_compilation_target(name, target_name) do
    name = String.downcase(name)
    target_name = String.downcase(target_name)

    cond do
      name == target_name -> true
      # compilation target appears to be replace spaces with underscores
      # https://github.com/celo-org/data-services/issues/151
      String.replace(target_name, ~r/\s/, "_") == name -> true
      true -> false
    end
  end

  defp prepare_additional_source(address_hash_string, %{"name" => _name, "content" => content, "path" => path}) do
    splitted_path =
      path
      |> String.split("/")

    trimmed_path =
      splitted_path
      |> Enum.slice(9..Enum.count(splitted_path))
      |> Enum.join("/")

    %{
      "address_hash" => address_hash_string,
      "file_name" => "/" <> trimmed_path,
      "contract_source_code" => content
    }
  end

  defp extract_primary_source_code(content, params) do
    params
    |> Map.put("contract_source_code", content)
  end

  def parse_json_from_sourcify_for_insertion(verification_metadata_json) do
    %{"name" => _, "content" => content} = verification_metadata_json
    content_json = Sourcify.decode_json(content)
    compiler_version = "v" <> (content_json |> Map.get("compiler") |> Map.get("version"))
    abi = content_json |> Map.get("output") |> Map.get("abi")
    settings = Map.get(content_json, "settings")
    compilation_target_file_path = settings |> Map.get("compilationTarget") |> Map.keys() |> Enum.at(0)
    compilation_target_file_name = compilation_target_file_path |> String.split("/") |> Enum.at(-1)
    contract_name = settings |> Map.get("compilationTarget") |> Map.get("#{compilation_target_file_path}")
    optimizer = Map.get(settings, "optimizer")

    params =
      %{}
      |> Map.put("name", contract_name)
      |> Map.put("compiler_version", compiler_version)
      |> Map.put("evm_version", Map.get(settings, "evmVersion"))
      |> Map.put("optimization", Map.get(optimizer, "enabled"))
      |> Map.put("optimization_runs", Map.get(optimizer, "runs"))
      |> Map.put("external_libraries", Map.get(settings, "libraries"))
      |> Map.put("verified_via_sourcify", true)

    %{
      "params_to_publish" => params,
      "abi" => abi,
      "compilation_target_file_path" => compilation_target_file_path,
      "compilation_target_file_name" => compilation_target_file_name,
      "secondary_sources" => []
    }
  end

  def parse_optimization_runs(%{"runs" => runs}) do
    case Integer.parse(runs) do
      {integer, ""} -> integer
      _ -> 200
    end
  end

  def check_and_verify(address_hash_string) do
    if Chain.smart_contract_fully_verified?(address_hash_string) do
      {:ok, :already_fully_verified}
    else
      if Application.get_env(:explorer, Explorer.ThirdPartyIntegrations.Sourcify)[:enabled] do
        if Chain.smart_contract_verified?(address_hash_string) do
          case Sourcify.check_by_address(address_hash_string) do
            {:ok, _verified_status} ->
              get_metadata_and_publish(address_hash_string, nil)

            _ ->
              {:error, :not_verified}
          end
        else
          case Sourcify.check_by_address_any(address_hash_string) do
            {:ok, "full", metadata} ->
              process_metadata_and_publish(address_hash_string, metadata, false)

            {:ok, "partial", metadata} ->
              process_metadata_and_publish(address_hash_string, metadata, true)

            _ ->
              {:error, :not_verified}
          end
        end
      else
        {:error, :sourcify_disabled}
      end
    end
  end
end
