class AddTrigramIndexesToEvents < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # Use concurrently to avoid locking writes for long
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_events_name_trgm
      ON events USING gin (name gin_trgm_ops);
    SQL

    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_events_venue_trgm
      ON events USING gin (venue gin_trgm_ops);
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX CONCURRENTLY IF EXISTS idx_events_name_trgm;
    SQL

    execute <<-SQL
      DROP INDEX CONCURRENTLY IF EXISTS idx_events_venue_trgm;
    SQL
  end
end
