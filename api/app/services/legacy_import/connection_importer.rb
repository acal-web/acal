module LegacyImport
  class ConnectionImporter
    NUMERO_PATTERN = /\A\s*(\d+)\s*(.*)\z/m
    Result = Struct.new(:imported, :skipped_duplicates, :skipped_invalid, keyword_init: true)

    def self.call(ligacao_path:)
      new(ligacao_path).call
    end

    def initialize(ligacao_path)
      @ligacao_path = ligacao_path
    end

    def call
      ligacoes = SqlDumpParser.call(@ligacao_path).fetch("enderecopessoa").rows

      imported = []
      skipped_duplicates = []
      skipped_invalid = []

      ligacoes.each do |row|
        legacy_id = row["id"].to_i
        next (skipped_duplicates << legacy_id) if Connection.exists?(legacy_id:)

        customer = Customer.find_by(legacy_id: row["idPessoa"].to_i)
        unless customer
          skipped_invalid << { legacy_id:, reason: "Sócio não encontrado (idPessoa=#{row['idPessoa']})" }
          next
        end

        address = Address.find_by(legacy_id: row["idEndereco"].to_i)
        unless address
          skipped_invalid << { legacy_id:, reason: "Endereço não encontrado (idEndereco=#{row['idEndereco']})" }
          next
        end

        category = Category.find_by(legacy_id: row["idCategoriaSocio"].to_i)
        unless category
          skipped_invalid << { legacy_id:, reason: "Categoria não encontrada (idCategoriaSocio=#{row['idCategoriaSocio']})" }
          next
        end

        number, letter = parse_numero(row["Numero"])
        if number.nil? || number <= 0
          skipped_invalid << { legacy_id:, reason: "Número inválido: #{row['Numero'].inspect}" }
          next
        end

        active = !bit_true?(row["inativo"])
        exclusively_member = bit_true?(row["socioExclusivo"])
        membership_date = row["datamatricula"].presence || "2000-01-01"

        imported << Connections::CreateService.call(
          customer_id: customer.id,
          address_id: address.id,
          category_id: category.id,
          number:,
          letter:,
          active:,
          legacy_id:,
          membership_date:,
          exclusively_member:
        )
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        skipped_invalid << { legacy_id:, reason: e.message }
      end

      Result.new(imported: imported.size, skipped_duplicates: skipped_duplicates.size, skipped_invalid:)
    end

    private

    def parse_numero(raw)
      return [ nil, nil ] if raw.blank?

      m = NUMERO_PATTERN.match(raw)
      return [ nil, nil ] unless m

      number = m[1].to_i
      letter = m[2].strip.sub(/\A[-\s]+/, "").strip.presence
      [ number, letter ]
    end

    def bit_true?(value)
      value == "\x01"
    end
  end
end
