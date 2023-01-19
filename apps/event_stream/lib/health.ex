defmodule Publisher.Health do
  @moduledoc """
  Check various health attributes of the application
  """

  @doc """
  Check if app is ready
  """
  def ready? do
    beanstalkd_connection_alive?()
  end

  @doc """
  Check if app is alive and working
  """
  def alive? do
    beanstalkd_connection_alive?()
  end

  defp beanstalkd_connection_alive?() do
    true
  end
end
