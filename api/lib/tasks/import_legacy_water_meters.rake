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
      count = 0

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

            conn.execute(
              "INSERT INTO legacy_hidrometro (idhidrometro, Consumo, idconta, consumo_inicial, consumo_final) " \
              "VALUES ($1, $2, $3, $4, $5) " \
              "ON CONFLICT (idhidrometro) DO NOTHING",
              [id, consumo, idconta, consumo_inicial, consumo_final]
            )
            count += 1
          rescue StandardError => e
            # Silently skip errors on individual rows
          end
        end
      end

      count
    end
  end
end
