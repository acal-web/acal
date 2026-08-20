namespace :db do
  namespace :legacy do
    desc "Import water meters from legacy SQL dump and migrate them"
    task import_water_meters: :environment do
      sql_file = Rails.root.join(".legacy/acal_hidrometro.sql")

      unless sql_file.exist?
        puts "❌ Legacy SQL file not found: #{sql_file}"
        exit 1
      end

      puts "📥 Importing water meters from legacy system..."

      # Read the SQL file
      sql_content = File.read(sql_file)

      # Create legacy_hidrometro table
      create_legacy_table

      # Extract and import data from INSERT statements
      count = extract_and_import_data(sql_content)
      puts "✓ Imported #{count} legacy water meter records"

      # Now run the migration
      puts "\n🔄 Running migration to map legacy data to invoices..."
      Rake::Task["db:migrate"].invoke
      puts "✓ Water meters migrated to new system"
    end

    private

    def create_legacy_table
      sql = <<~SQL
        CREATE TABLE IF NOT EXISTS legacy_hidrometro (
          idhidrometro INTEGER PRIMARY KEY,
          Consumo DOUBLE PRECISION,
          idconta INTEGER,
          consumo_inicial DOUBLE PRECISION,
          consumo_final DOUBLE PRECISION
        )
      SQL

      ActiveRecord::Base.connection.execute(sql)
      puts "✓ Created legacy_hidrometro staging table"
    end

    def extract_and_import_data(sql_content)
      conn = ActiveRecord::Base.connection
      batch = []
      batch_size = 5000
      total_count = 0

      # Extract all INSERT statements
      # Format: INSERT INTO `hidrometro` VALUES (id,consumo,idconta,consumo_inicial,consumo_final),...;
      sql_content.scan(/INSERT INTO `hidrometro` VALUES\s*(.*?);/m) do |match|
        values_str = match[0]

        # Parse each row: (id,consumo,idconta,consumo_inicial,consumo_final)
        values_str.scan(/\(([^)]+)\)/) do |row|
          parts = row[0].split(",")
          next if parts.length < 5

          begin
            id = parts[0].strip.to_i
            consumo = parts[1].strip == "NULL" ? nil : parts[1].strip.to_f
            idconta = parts[2].strip.to_i
            consumo_inicial = parts[3].strip == "NULL" ? nil : parts[3].strip.to_f
            consumo_final = parts[4].strip == "NULL" ? nil : parts[4].strip.to_f

            batch << {
              idhidrometro: id,
              consumo: consumo,
              idconta: idconta,
              consumo_inicial: consumo_inicial,
              consumo_final: consumo_final
            }

            if batch.size >= batch_size
              import_batch(conn, batch)
              total_count += batch.size
              puts "  ✓ #{total_count} records imported..."
              batch = []
            end
          rescue StandardError => e
            puts "  ⚠ Erro ao processar linha: #{e.message}"
          end
        end
      end

      # Import remaining batch
      if batch.any?
        import_batch(conn, batch)
        total_count += batch.size
      end

      total_count
    end

    def import_batch(conn, batch)
      values_clause = batch.map do |row|
        "(#{row[:idhidrometro]}, #{row[:consumo].nil? ? 'NULL' : row[:consumo]}, #{row[:idconta]}, #{row[:consumo_inicial].nil? ? 'NULL' : row[:consumo_inicial]}, #{row[:consumo_final].nil? ? 'NULL' : row[:consumo_final]})"
      end.join(",\n")

      sql = <<~SQL
        INSERT INTO legacy_hidrometro (idhidrometro, Consumo, idconta, consumo_inicial, consumo_final)
        VALUES #{values_clause}
        ON CONFLICT (idhidrometro) DO NOTHING
      SQL

      conn.execute(sql)
    rescue StandardError => e
      puts "  ❌ Erro ao importar batch: #{e.message}"
    end
  end
end
