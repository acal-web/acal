module Test
  module DatabaseReset
    def self.call
      raise "refusing to run outside RAILS_ENV=test" unless Rails.env.test?

      conn = ActiveRecord::Base.connection
      tables = conn.tables - %w[schema_migrations ar_internal_metadata]
      conn.disable_referential_integrity do
        tables.each { |t| conn.execute("TRUNCATE TABLE #{conn.quote_table_name(t)} RESTART IDENTITY CASCADE") }
      end
    end
  end
end
