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

      imported = []
      skipped_duplicates = []
      skipped_invalid = []

      enderecos.each do |row|
        legacy_id = row["id"].to_i
        next (skipped_duplicates << legacy_id) if Address.exists?(legacy_id:)

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

        form = AddressForm.new(
          name:,
          legacy_id:,
        )

        imported << Address.create!(**form.to_h)
      rescue ActiveRecord::RecordInvalid => e
        skipped_invalid << { legacy_id:, reason: e.message }
      rescue ActiveRecord::RecordNotUnique => e
        skipped_invalid << { legacy_id:, reason: "Endereço duplicado: #{name} já existe" }
      end

      Result.new(imported: imported.size, skipped_duplicates: skipped_duplicates.size, skipped_invalid:)
    end
  end
end
