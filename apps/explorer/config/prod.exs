use Mix.Config

# Configures the database
config :explorer, Explorer.Repo,
  url: System.get_env("DATABASE_URL") || "postgresql://postgres:1234@localhost:5432/blockscout",
  username: System.get_env("DATABASE_USER") || "postgres",
  password: System.get_env("DATABASE_PASSWORD") || "1234",
  database: System.get_env("DATABASE_DB") || "blockscout",
  hostname: System.get_env("DATABASE_HOSTNAME") || "localhost",
  port: System.get_env("DATABASE_PORT") || "5432",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "50"),
  ssl: String.equivalent?(System.get_env("ECTO_USE_SSL") || "true", "true"),
  prepare: :unnamed,
  parameters: [application_name: System.get_env("HOSTNAME", "blockscout-production")],
  timeout: :timer.seconds(60)

config :explorer, Explorer.Tracer, env: "production", disabled?: true

config :explorer, :voter_rewards_for_group, Explorer.Celo.VoterRewardsForGroup

config :logger, :explorer,
  level: :info,
  path: Path.absname("logs/prod/explorer.log"),
  rotate: %{max_bytes: 52_428_800, keep: 19}

config :logger, :reading_token_functions,
  level: :debug,
  path: Path.absname("logs/prod/explorer/tokens/reading_functions.log"),
  metadata_filter: [fetcher: :token_functions],
  rotate: %{max_bytes: 52_428_800, keep: 19}

config :logger, :token_instances,
  level: :debug,
  path: Path.absname("logs/prod/explorer/tokens/token_instances.log"),
  metadata_filter: [fetcher: :token_instances],
  rotate: %{max_bytes: 52_428_800, keep: 19}

variant =
  if is_nil(System.get_env("ETHEREUM_JSONRPC_VARIANT")) do
    "parity"
  else
    System.get_env("ETHEREUM_JSONRPC_VARIANT")
    |> String.split(".")
    |> List.last()
    |> String.downcase()
  end

config :explorer, Explorer.Celo.CoreContracts, enabled: true, refresh: :timer.hours(1)
config :explorer, Explorer.Celo.AddressCache, Explorer.Celo.CoreContracts

# Import variant specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "prod/#{variant}.exs"
