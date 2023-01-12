import Config

config :indexer, Indexer.Prometheus.MetricsCron, metrics_fetcher_blocks_count: 1000
config :indexer, Indexer.Prometheus.MetricsCron, metrics_cron_interval: System.get_env("METRICS_CRON_INTERVAL") || "2"

config :indexer, :telemetry_config,[
  [
    name: [:blockscout, :chain_event_send],
    type: :counter,
    metric_id: "indexer_chain_events_sent",
    meta: %{
      help: "Number of chain events sent via pubsub"
    }
  ]
]
