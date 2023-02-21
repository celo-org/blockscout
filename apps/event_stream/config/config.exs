import Config

config :event_stream, :buffer_flush_interval, :timer.seconds(5)
config :event_stream, EventStream.Publisher, EventStream.Publisher.Beanstalkd

config :event_stream, :beanstalkd, enabled: false

import_config "#{config_env()}.exs"