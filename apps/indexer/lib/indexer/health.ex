defmodule Indexer.Health do
  @moduledoc """
  Check various health attributes of the application
  """


  @doc """
  Check if app is alive and working, by making a simple
  request to the DB
  """
  def is_alive? do
    !!Ecto.Adapters.SQL.query!(Explorer.Repo, "SELECT 1")
  rescue
    _e -> false
  end
end
