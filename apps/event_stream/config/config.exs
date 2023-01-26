import Config


config :event_stream, :buffer_flush_interval, :timer.seconds(5)