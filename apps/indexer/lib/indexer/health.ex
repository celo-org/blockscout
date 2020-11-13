defmodule Indexer.Health do
  @moduledoc """
  Check various health attributes of the application
  """

  alias Ecto.Adapters.SQL

  @doc """
  Check if app is alive and working, by making a simple
  request to the DB
  """
  def alive? do
    SQL.query!(Explorer.Repo, "SELECT 1")
    true
  rescue
    _e -> false
  end
end
