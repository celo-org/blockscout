defmodule Explorer.Admin do
  @moduledoc """
  Context for performing administrative tasks.
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias Explorer.{Accounts, Repo}
  alias Explorer.Accounts.User
  alias Explorer.Admin.{Administrator, Recovery}

  @doc """
  Fetches the owner of the explorer.
  """
  @spec owner :: {:ok, Administrator.t()} | {:error, :not_found}
  def owner do
    query =
      from(a in Administrator,
        where: a.role == "owner",
        preload: [:user]
      )

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      admin ->
        {:ok, admin}
    end
  end

  @doc """
  Retrieves an admin record from a user
  """
  def from_user(%User{id: user_id}) do
    query =
      from(a in Administrator,
        where: a.user_id == ^user_id
      )

    case Repo.one(query) do
      %Administrator{} = admin ->
        {:ok, admin}

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Registers a new user as an administrator with the `owner` role.
  """
  @spec register_owner(map()) :: {:ok, %{user: User.t(), admin: Administrator.t()}} | {:error, Changeset.t()}
  def register_owner(params) do
    register_operation = Ecto.Multi.new()
    |> Ecto.Multi.run(:create_account, fn _repo, _changes ->
      Accounts.register_new_account(params)
    end)
    |> Ecto.Multi.run(:promote_user, fn
      _repo, %{create_account: user} ->
        promote_user(user, "owner")
    end)
    |> Ecto.Multi.run(:handle_result, fn
      _repo, %{create_account: user, promote_user: admin} ->
      {:ok, %{admin: admin, user: user}}
    end)

   case register_operation |> Repo.transaction() do
     {:ok, %{handle_result: result}} ->
       {:ok, result}

     {:error, _failed_stage, failed_changeset, _changes} ->
       {:error, failed_changeset}
   end
  end

  defp promote_user(%User{id: user_id}, role) do
    %Administrator{}
    |> Administrator.changeset(%{user_id: user_id, role: role})
    |> Repo.insert()
  end

  def recovery_key do
    Recovery.key(Recovery)
  end
end
