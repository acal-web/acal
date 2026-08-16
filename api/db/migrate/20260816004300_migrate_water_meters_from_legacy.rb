class MigrateWaterMetersFromLegacy < ActiveRecord::Migration[8.1]
  def up
    # Migrate water meters from legacy system
    # The legacy table structure is:
    # - idhidrometro: int (legacy ID)
    # - idconta: int (legacy invoice ID)
    # - consumo_inicial: double (initial reading)
    # - consumo_final: double (final reading)

    # This migration requires a legacy_hidrometro table to be available
    # It maps:
    # - idhidrometro → legacy_id
    # - idconta → invoice.legacy_id
    # - consumo_inicial → initial_reading
    # - consumo_final → final_reading

    say "Starting water meter migration from legacy system..."

    sql = <<~SQL
      INSERT INTO water_meters (id, invoice_id, measured_at, initial_reading, final_reading, legacy_id, created_at, updated_at)
      SELECT
        gen_random_uuid(),
        i.id,
        i.reference_date,
        CAST(hm.consumo_inicial AS NUMERIC(10,2)),
        CAST(hm.consumo_final AS NUMERIC(10,2)),
        hm.idhidrometro,
        NOW(),
        NOW()
      FROM legacy_hidrometro hm
      INNER JOIN invoices i ON i.legacy_id = hm.idconta
      WHERE hm.consumo_inicial IS NOT NULL
        AND hm.consumo_final IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM water_meters WHERE legacy_id = hm.idhidrometro)
    SQL

    begin
      # Check if legacy table exists
      legacy_exists = select_one(
        "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'legacy_hidrometro') AS exists"
      )

      if legacy_exists && legacy_exists["exists"]
        result = execute(sql)
        rows = result.cmd_tuples rescue result.ntuples rescue 0
        say "✓ Migrated #{rows} water meters from legacy system"
      else
        say "⚠ Legacy hydrometro table not found, skipping migration"
      end
    rescue StandardError => e
      say "⚠ Migration skipped: #{e.message}"
    end
  end

  def down
    # Remove migrated water meters (those with legacy_id set)
    execute "DELETE FROM water_meters WHERE legacy_id IS NOT NULL"
    say "Removed water meters migrated from legacy system"
  end
end
