defmodule BlockScoutWeb.WebRouter do
  @moduledoc """
  Router for web app
  """
  use BlockScoutWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(BlockScoutWeb.CSPHeader)
    plug(BlockScoutWeb.ChecksumAddress)
    plug(BlockScoutWeb.Plug.ValidateRouteParameters)
  end

  # Disallows Iframes (write routes)
  scope "/", BlockScoutWeb do
    pipe_through(:browser)
  end

  # Allows Iframes (read-only routes)
  scope "/", BlockScoutWeb do
    pipe_through([:browser, BlockScoutWeb.Plug.AllowIframe])

    resources("/", ChainController, only: [:show], singleton: true, as: :chain)

    resources("/market-history-chart", Chain.MarketHistoryChartController,
      only: [:show],
      singleton: true
    )

    resources("/transaction-history-chart", Chain.TransactionHistoryChartController,
      only: [:show],
      singleton: true
    )

    resources "/block", BlockController, only: [:show], param: "hash_or_number" do
      resources("/transactions", BlockTransactionController, only: [:index], as: :transaction)
      resources("/epoch-transactions", BlockEpochTransactionController, only: [:index], as: :epoch_transaction)
      resources("/signers", BlockSignersController, only: [:index], as: :signers)
    end

    resources("/blocks", BlockController, as: :blocks, only: [:index])

    resources "/blocks", BlockController, only: [:show], param: "hash_or_number" do
      resources("/transactions", BlockTransactionController, only: [:index], as: :transaction)
    end

    get("/validators", StakesController, :index, as: :validators, assigns: %{filter: :validator})
    get("/active-pools", StakesController, :index, as: :active_pools, assigns: %{filter: :active})
    get("/inactive-pools", StakesController, :index, as: :inactive_pools, assigns: %{filter: :inactive})

    resources("/pending-transactions", PendingTransactionController, only: [:index])

    resources("/recent-transactions", RecentTransactionsController, only: [:index])

    get("/txs", TransactionController, :index)

    resources "/tx", TransactionController, only: [:show] do
      resources(
        "/internal-transactions",
        TransactionInternalTransactionController,
        only: [:index],
        as: :internal_transaction
      )

      resources(
        "/raw-trace",
        TransactionRawTraceController,
        only: [:index],
        as: :raw_trace
      )

      resources("/logs", TransactionLogController, only: [:index], as: :log)

      resources("/token-transfers", TransactionTokenTransferController,
        only: [:index],
        as: :token_transfer
      )
    end

    resources("/accounts", AddressController, only: [:index])

    resources("/tokens", TokensController, only: [:index])

    resources("/bridged-tokens", BridgedTokensController, only: [:index, :show])

    resources "/address", AddressController, only: [:show], private: %{validate: %{"address_id" => :is_address}} do
      resources("/transactions", AddressTransactionController, only: [:index], as: :transaction)

      resources(
        "/internal-transactions",
        AddressInternalTransactionController,
        only: [:index],
        as: :internal_transaction
      )

      resources(
        "/validations",
        AddressValidationController,
        only: [:index],
        as: :validation
      )

      resources(
        "/celo",
        AddressCeloController,
        only: [:index],
        as: :celo
      )

      resources(
        "/epoch-transactions",
        AddressEpochTransactionController,
        only: [:index],
        as: :epoch_transaction
      )

      resources(
        "/signed",
        AddressSignedController,
        only: [:index],
        as: :signed
      )

      resources(
        "/contracts",
        AddressContractController,
        only: [:index],
        as: :contract
      )

      resources(
        "/decompiled-contracts",
        AddressDecompiledContractController,
        only: [:index],
        as: :decompiled_contract
      )

      resources(
        "/logs",
        AddressLogsController,
        only: [:index],
        as: :logs
      )

      resources(
        "/contract-verifications",
        AddressContractVerificationController,
        only: [:new],
        as: :verify_contract
      )

      resources(
        "/verify-via-flattened-code",
        AddressContractVerificationViaFlattenedCodeController,
        only: [:new],
        as: :verify_contract_via_flattened_code
      )

      resources(
        "/verify-via-metadata-json",
        AddressContractVerificationViaJsonController,
        only: [:new, :create],
        as: :verify_contract_via_json
      )

      resources(
        "/verify-via-standard-json-input",
        AddressContractVerificationViaStandardJsonInputController,
        only: [:new],
        as: :verify_contract_via_standard_json_input
      )

      resources(
        "/verify-vyper-contract",
        AddressContractVerificationVyperController,
        only: [:new, :create],
        as: :verify_vyper_contract
      )

      resources(
        "/read-contract",
        AddressReadContractController,
        only: [:index],
        as: :read_contract
      )

      resources(
        "/read-proxy",
        AddressReadProxyController,
        only: [:index],
        as: :read_proxy
      )

      resources(
        "/write-contract",
        AddressWriteContractController,
        only: [:index],
        as: :write_contract
      )

      resources(
        "/write-proxy",
        AddressWriteProxyController,
        only: [:index],
        as: :write_proxy
      )

      resources(
        "/token-transfers",
        AddressTokenTransferController,
        only: [:index],
        as: :token_transfers
      )

      resources("/tokens", AddressTokenController, only: [:index], as: :token) do
        resources(
          "/token-transfers",
          AddressTokenTransferController,
          only: [:index],
          as: :transfers
        )
      end

      resources(
        "/token-balances",
        AddressTokenBalanceController,
        only: [:index],
        as: :token_balance
      )

      resources(
        "/coin-balances",
        AddressCoinBalanceController,
        only: [:index],
        as: :coin_balance
      )

      resources(
        "/coin-balances/by-day",
        AddressCoinBalanceByDayController,
        only: [:index],
        as: :coin_balance_by_day
      )
    end

    resources "/token", Tokens.TokenController, only: [:show], as: :token do
      resources(
        "/token-transfers",
        Tokens.TransferController,
        only: [:index],
        as: :transfer
      )

      resources(
        "/read-contract",
        Tokens.ContractController,
        only: [:index],
        as: :read_contract
      )

      resources(
        "/write-contract",
        Tokens.ContractController,
        only: [:index],
        as: :write_contract
      )

      resources(
        "/read-proxy",
        Tokens.ContractController,
        only: [:index],
        as: :read_proxy
      )

      resources(
        "/write-proxy",
        Tokens.ContractController,
        only: [:index],
        as: :write_proxy
      )

      resources(
        "/token-holders",
        Tokens.HolderController,
        only: [:index],
        as: :holder
      )

      resources(
        "/inventory",
        Tokens.InventoryController,
        only: [:index],
        as: :inventory
      )

      resources(
        "/instance",
        Tokens.InstanceController,
        only: [:show],
        as: :instance
      ) do
        resources(
          "/token-transfers",
          Tokens.Instance.TransferController,
          only: [:index],
          as: :transfer
        )

        resources(
          "/metadata",
          Tokens.Instance.MetadataController,
          only: [:index],
          as: :metadata
        )

        resources(
          "/token-holders",
          Tokens.Instance.HolderController,
          only: [:index],
          as: :holder
        )
      end
    end

    resources "/tokens", Tokens.TokenController, only: [:show], as: :token_secondary do
      resources(
        "/token-transfers",
        Tokens.TransferController,
        only: [:index],
        as: :transfer
      )

      resources(
        "/read-contract",
        Tokens.ContractController,
        only: [:index],
        as: :read_contract
      )

      resources(
        "/write-contract",
        Tokens.ContractController,
        only: [:index],
        as: :write_contract
      )

      resources(
        "/read-proxy",
        Tokens.ContractController,
        only: [:index],
        as: :read_proxy
      )

      resources(
        "/write-proxy",
        Tokens.ContractController,
        only: [:index],
        as: :write_proxy
      )

      resources(
        "/token-holders",
        Tokens.HolderController,
        only: [:index],
        as: :holder
      )

      resources(
        "/inventory",
        Tokens.InventoryController,
        only: [:index],
        as: :inventory
      )

      resources(
        "/instance",
        Tokens.InstanceController,
        only: [:show],
        as: :instance
      ) do
        resources(
          "/token-transfers",
          Tokens.Instance.TransferController,
          only: [:index],
          as: :transfer
        )

        resources(
          "/metadata",
          Tokens.Instance.MetadataController,
          only: [:index],
          as: :metadata
        )

        resources(
          "/token-holders",
          Tokens.Instance.HolderController,
          only: [:index],
          as: :holder
        )
      end
    end

    resources(
      "/smart-contracts",
      SmartContractController,
      only: [:index, :show],
      as: :smart_contract
    )

    resources(
      "/contract-verifications",
      AddressContractVerificationController,
      only: [:new],
      as: :verify_contract
    )

    get("/address-counters", AddressController, :address_counters)

    get("/search", ChainController, :search)

    get("/search-logs", AddressLogsController, :search_logs)

    get("/search-results", SearchController, :search_results)

    get("/csv-export", CsvExportController, :index)

    post("/captcha", CaptchaController, :index)

    get("/transactions-csv", AddressTransactionController, :transactions_csv)

    get("/token-autocomplete", ChainController, :token_autocomplete)

    get("/token-transfers-csv", AddressTransactionController, :token_transfers_csv)

    get("/epoch-transactions-csv", AddressTransactionController, :epoch_transactions_csv)

    get("/internal-transactions-csv", AddressTransactionController, :internal_transactions_csv)

    get("/logs-csv", AddressTransactionController, :logs_csv)

    get("/chain-blocks", ChainController, :chain_blocks, as: :chain_blocks)

    get("/token-counters", Tokens.TokenController, :token_counters)

    get("/stats", StatsController, :index)

    get("/makerdojo", MakerdojoController, :index)

    get("/verified-contracts", VerifiedContractsController, :index)

    get("/*path", PageNotFoundController, :index)
  end
end
