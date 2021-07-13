defmodule Explorer.Repo.ConfigHelperTest do
  use Explorer.DataCase, async: false

  alias Explorer.Repo.ConfigHelper

  describe "get_db_config/1" do
    setup do
      previous_env = System.get_env()

      on_exit(fn ->
        System.put_env(%{"PGUSER" => "", "PGPASSWORD" => "", "DATABASE_USER" => ""})
        System.put_env(previous_env)
      end)
    end

    test "parse params from database url" do
      database_url = "postgresql://test_username:test_password@127.8.8.1:7777/test_database"

      result = ConfigHelper.get_db_config(%{url: database_url})

      assert result[:username] == "test_username"
      assert result[:password] == "test_password"
      assert result[:hostname] == "127.8.8.1"
      assert result[:port] == "7777"
      assert result[:database] == "test_database"
    end

    test "get username without password" do
      database_url = "postgresql://test_username:@127.8.8.1:7777/test_database"

      result = ConfigHelper.get_db_config(%{url: database_url})

      assert result[:username] == "test_username"
      refute result[:password]
      assert result[:hostname] == "127.8.8.1"
      assert result[:port] == "7777"
      assert result[:database] == "test_database"
    end

    test "get hostname instead of ip" do
      database_url = "postgresql://test_username:@cooltesthost:7777/test_database"

      result = ConfigHelper.get_db_config(%{url: database_url})

      assert result[:username] == "test_username"
      refute result[:password]
      assert result[:hostname] == "cooltesthost"
      assert result[:port] == "7777"
      assert result[:database] == "test_database"
    end

    test "overwrite database url param with postgrex vars" do
      database_url = "postgresql://test_username:@127.8.8.1:7777/test_database"

      System.put_env(%{"PGUSER" => "postgrex_user", "PGPASSWORD" => "postgrex_password"})
      result = ConfigHelper.get_db_config(%{url: database_url})

      assert result[:username] == "postgrex_user"
      assert result[:password] == "postgrex_password"
      assert result[:hostname] == "127.8.8.1"
      assert result[:port] == "7777"
      assert result[:database] == "test_database"
    end

    test "overwrite database url param and postgrex with app env" do
      database_url = "postgresql://test_username:@127.8.8.1:7777/test_database"

      System.put_env(%{
        "PGUSER" => "postgrex_user",
        "PGPASSWORD" => "postgrex_password",
        "DATABASE_USER" => "app_db_user"
      })

      result = ConfigHelper.get_db_config(%{url: database_url})

      assert result[:username] == "app_db_user"
      assert result[:password] == "postgrex_password"
      assert result[:hostname] == "127.8.8.1"
      assert result[:port] == "7777"
      assert result[:database] == "test_database"
    end
  end
end
