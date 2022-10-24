defmodule Explorer.Repo.Local do
  use Ecto.Repo,
    otp_app: :explorer,
    adapter: Ecto.Adapters.Postgres

  use Explorer.Repo.RepoHelper

  require Logger

  alias Explorer.Repo.ConfigHelper

  @env Mix.env()

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    db_url = System.get_env("DATABASE_URL")
    repo_conf = Application.get_env(:explorer, Explorer.Repo.Local)

    merged =
      %{url: db_url}
      |> ConfigHelper.get_db_config()
      |> Keyword.merge(repo_conf, fn
        _key, v1, nil -> v1
        _key, nil, v2 -> v2
        _, _, v2 -> v2
      end)

    Application.put_env(:explorer, Explorer.Repo.Local, merged)

    extra_postgres_parameters = [application_name: get_application_name()]

    opts =
      Keyword.update(opts, :parameters, extra_postgres_parameters, fn params ->
        Keyword.merge(params, extra_postgres_parameters)
      end)
      |> Keyword.put(:url, db_url)


    Fly.Postgres.config_repo_url(opts, @env)
  end

  def get_application_name do
    case Mix.env() do
      :dev ->
        System.get_env("USER", "anon") <> "_dev_blockscout"

      :prod ->
        System.get_env("HOSTNAME", "blockscout_production")

      _ ->
        "blockscout"
    end
  end
end

defmodule Explorer.Repo do
  use Fly.Repo, local_repo: Explorer.Repo.Local
  require Logger

  use Explorer.Repo.RepoHelper

  def replica, do: __MODULE__
end
