module LegacyImport
  class CategoryImporter
    GROUP_MAP = { "1" => "fundador", "2" => "efetivo", "3" => "temporario" }.freeze
    Result = Struct.new(:imported, :skipped_duplicates, :skipped_invalid, keyword_init: true)

    def self.call(categoria_path:, taxa_path:)
      new(categoria_path, taxa_path).call
    end

    def initialize(categoria_path, taxa_path)
      @categoria_path = categoria_path
      @taxa_path = taxa_path
    end

    def call
      categorias = SqlDumpParser.call(@categoria_path).fetch("categoriasocio").rows
      taxas_by_id = SqlDumpParser.call(@taxa_path).fetch("taxa").rows.index_by { |r| r["id"].to_i }
      existing_legacy_ids = Set.new(Category.pluck(:legacy_id))

      imported = 0
      skipped_duplicates = 0
      skipped_invalid = []
      batch = []
      batch_size = 1000

      categorias.each do |row|
        legacy_id = row["id"].to_i

        if existing_legacy_ids.include?(legacy_id)
          skipped_duplicates += 1
          next
        end

        # Reject if group_id is NULL
        if row["group_id"].nil?
          skipped_invalid << { legacy_id:, reason: "group_id não pode ser nulo" }
          next
        end

        group = GROUP_MAP[row["group_id"]] || "temporario"

        taxa = taxas_by_id[row["taxasId"]&.to_i]
        unless taxa
          skipped_invalid << { legacy_id:, reason: "taxa não encontrada: #{row['taxasId']}" }
          next
        end

        has_water_meter = row["nome"].to_s.downcase.include?("hidrômetro") || row["nome"].to_s.downcase.include?("hidrometro")

        name = row["nome"]
        batch << {
          name:,
          description: row["descricao"],
          group:,
          has_water_meter:,
          membership_price: (taxa["valor_socio"] || "0").to_d,
          water_price: (taxa["valor"] || "0").to_d,
          legacy_id:,
          created_at: Time.current,
          updated_at: Time.current
        }

        if batch.size >= batch_size
          imported += batch.size
          Category.insert_all(batch)
          batch = []
        end
      rescue StandardError => e
        skipped_invalid << { legacy_id:, reason: e.message }
      end

      # Insert remaining batch
      if batch.any?
        imported += batch.size
        Category.insert_all(batch)
      end

      Result.new(imported:, skipped_duplicates:, skipped_invalid:)
end
  end
end
