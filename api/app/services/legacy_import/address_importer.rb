module LegacyImport
  class AddressImporter
    Result = Struct.new(:imported, :skipped_duplicates, :skipped_invalid, keyword_init: true)

    def self.call(endereco_path:)
      new(endereco_path).call
    end

    def initialize(endereco_path)
      @endereco_path = endereco_path
    end

    def call
      enderecos = SqlDumpParser.call(@endereco_path).fetch("endereco").rows
      existing_legacy_ids = Set.new(Address.pluck(:legacy_id))

      imported = 0
      skipped_duplicates = 0
      skipped_invalid = []
      batch = []
      batch_size = 1000

      enderecos.each do |row|
        legacy_id = row["id"].to_i

        if existing_legacy_ids.include?(legacy_id)
          skipped_duplicates += 1
          next
        end

        kind = (row["tipo"] || "").strip
        nome = (row["nome"] || "").strip

        # Merge kind and name: "Rua" + "das Flores" -> "Rua das Flores"
        name = if kind.present? && nome.present?
                 "#{kind} #{nome}"
        elsif kind.present?
                 kind
        elsif nome.present?
                 nome
        end

        if name.blank?
          skipped_invalid << { legacy_id:, reason: "Nome vazio" }
          next
        end

        batch << {
          name:,
          legacy_id:,
          tags: [],
          created_at: Time.current,
          updated_at: Time.current
        }

        if batch.size >= batch_size
          imported += batch.size
          Address.insert_all(batch, ignore_duplicates: true)
          batch = []
        end
      rescue StandardError => e
        skipped_invalid << { legacy_id:, reason: e.message }
      end

      # Insert remaining batch
      if batch.any?
        imported += batch.size
        Address.insert_all(batch, ignore_duplicates: true)
      end

      Result.new(imported:, skipped_duplicates:, skipped_invalid:)
end
  end
end
