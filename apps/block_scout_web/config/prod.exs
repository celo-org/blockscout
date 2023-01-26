import Config

# For production, we often load configuration from external
# sources, such as your system environment. For this reason,
# you won't find the :http configuration below, but set inside
# BlockScoutWeb.Endpoint.init/2 when load_from_system_env is
# true. Any dynamic configuration should be done there.
#
# Don't forget to configure the url host to something meaningful,
# Phoenix uses this information when generating URLs.
#
# Finally, we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the mix phx.digest task
# which you typically run after static files are built.
config :block_scout_web, BlockScoutWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  force_ssl: false

config :block_scout_web, BlockScoutWeb.Tracer, env: "production", disabled?: true

config :block_scout_web, :environment, :prod

config :logger, :block_scout_web,
  level: :info,
  path: Path.absname("logs/prod/block_scout_web.log"),
  rotate: %{max_bytes: 52_428_800, keep: 19}

config :logger, :api,
  level: :debug,
  path: Path.absname("logs/prod/api.log"),
  metadata_filter: [fetcher: :api],
  rotate: %{max_bytes: 52_428_800, keep: 19}

config :explorer, Explorer.ExchangeRates,
  enabled: if(System.get_env("DISABLE_EXCHANGE_RATES", "false") == "false", do: false, else: true)



config :block_scout_web, :captcha_helper, BlockScoutWeb.CaptchaHelper
