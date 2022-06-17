defmodule Explorer.Repo.Migrations.SetCountersOnTransactionTable do
  use Ecto.Migration

  def up do
    execute("""
    START TRANSACTION;

    CREATE TABLE celo_transaction_stats(stat_type varchar(255), value bigint);

    CREATE FUNCTION celo_transaction_stats_trigger_func() RETURNS trigger
    LANGUAGE plpgsql AS
    $$BEGIN
    IF TG_OP = 'INSERT' THEN
      UPDATE celo_transaction_stats SET value = value + 1 WHERE stat_type = 'total_transaction_count';
      UPDATE celo_transaction_stats SET value = value + NEW.gas_used WHERE stat_type = 'total_gas_used';

      RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
      UPDATE celo_transaction_stats SET value = value - 1 WHERE stat_type = 'total_transaction_count';
      UPDATE celo_transaction_stats SET value = value - OLD.gas_used WHERE stat_type = 'total_gas_used';

      RETURN OLD;
    ELSE IF TG_OP = 'UPDATE' THEN
      UPDATE celo_transaction_stats SET value = value + (NEW.gas_used - OLD.gas_used) WHERE stat_type = 'total_gas_used';

      RETURN NEW;
    ELSE IF TG_OP = 'TRUNCATE' THEN
      UPDATE celo_transaction_stats SET value = 0 WHERE stat_type = 'total_transaction_count';
      UPDATE celo_transaction_stats SET value = 0 WHERE stat_type = 'total_gas_used';

      RETURN NULL;
    END IF;
    END;$$;

    CREATE CONSTRAINT TRIGGER celo_transaction_stats_modified
    AFTER INSERT OR DELETE ON transactions
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE celo_transaction_stats_trigger_func();

    -- TRUNCATE triggers must be FOR EACH STATEMENT
    CREATE TRIGGER celo_transaction_stats_truncated AFTER TRUNCATE ON transactions
    FOR EACH STATEMENT EXECUTE PROCEDURE celo_transaction_stats_trigger_func();

    INSERT INTO celo_transaction_stats VALUES ('total_transaction_count', (SELECT count(*) FROM transactions));
    INSERT INTO celo_transaction_stats VALUES ('total_gas_used', (SELECT sum(gas_used) FROM transactions));

    COMMIT;
    """)
  end

  def down do
    execute("""
    DROP TRIGGER celo_transaction_stats_truncated;
    DROP TRIGGER celo_transaction_stats_modified;
    DROP FUNCTION celo_transaction_stats_trigger_func;
    DROP TABLE celo_transaction_stats;
    """)
  end
end
