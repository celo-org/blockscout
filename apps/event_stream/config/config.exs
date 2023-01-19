# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

beanstalkd_host = "BEANSTALKD_HOST" |> System.get_env("127.0.0.1") |> to_charlist()
{beanstalkd_port, _} = "BEANSTALKD_PORT" |> System.get_env("11300") |> Integer.parse()
beanstalkd_tube = "BEANSTALKD_TUBE" |> System.get_env("default")

config :event_stream, EventStream.Celo.Events.ContractEventStream,
  host: beanstalkd_host,
  port: beanstalkd_port,
  tube: beanstalkd_tube,
  enabled: System.get_env("ENABLE_EVENT_STREAM", "false") == "true"
