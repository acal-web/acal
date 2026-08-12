module LegacyImport
  class CustomerImporter
    Result = Struct.new(:imported, :skipped_duplicates, :skipped_invalid, keyword_init: true)

    def self.call(pessoa_path:)
      new(pessoa_path).call
    end

    def initialize(pessoa_path)
      @pessoa_path = pessoa_path
    end

    def call
      pessoas = SqlDumpParser.call(@pessoa_path).fetch("pessoa").rows

      imported = []
      skipped_duplicates = []
      skipped_invalid = []

      pessoas.each do |row|
        legacy_id = row["id"].to_i
        next (skipped_duplicates << legacy_id) if Customer.exists?(legacy_id:)

        # Clean and combine names
        nome = (row["nome"] || "").strip
        sobrenome = (row["sobrenome"] || "").strip
        name = [ nome, sobrenome ].reject(&:empty?).join(" ")

        if name.blank?
          skipped_invalid << { legacy_id:, reason: "Nome vazio" }
          next
        end

        # Use CPF if available, otherwise CNPJ, or empty string for legacy data
        document = (row["cpf"] || row["cnpj"] || "").to_s.strip

        membership_number = row["numeroMatricula"]&.to_i

        customer = Customer.create!(
          name:,
          document:,
          membership_number:,
          legacy_id:,
          validate: false,
        )
        imported << customer
      rescue ActiveRecord::RecordNotUnique => e
        skipped_invalid << { legacy_id:, reason: e.message }
      end

      Result.new(imported: imported.size, skipped_duplicates: skipped_duplicates.size, skipped_invalid:)
    end
  end
end
