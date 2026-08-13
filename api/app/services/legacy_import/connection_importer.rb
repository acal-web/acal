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
          number = next_available_number
          tags = []
          tags << "invalid number"
        else
          tags = []
        end

        active = !bit_true?(row["inativo"])
        exclusively_member = bit_true?(row["socioExclusivo"])
        membership_date = row["datamatricula"].presence || "2000-01-01"

        # Try to insert, handling duplicate letter by adding numeric suffix
        connection = create_with_unique_letter(
          customer_id: customer.id,
          address_id: address.id,
          category_id: category.id,
          number:,
          letter:,
          active:,
          legacy_id:,
          membership_date:,
          exclusively_member:,
          tags:,
        )
        imported << connection
      rescue ActiveRecord::RecordInvalid => e
        skipped_invalid << { legacy_id:, reason: e.message }
      end

      Result.new(imported: imported.size, skipped_duplicates: skipped_duplicates.size, skipped_invalid:)
    end

    private

    def next_available_number
      max_number = Connection.maximum(:number).to_i
      max_number + 1
    end

    def create_with_unique_letter(params)
      letter = params[:letter]
      attempt = 0
      max_attempts = 100

      loop do
        begin
          return Connections::CreateService.call(**params)
        rescue ActiveRecord::RecordNotUnique => e
          # Check if it's the letter/number unique constraint
          if e.message.include?("address_id") && e.message.include?("number")
            attempt += 1
            if attempt > max_attempts
              raise ActiveRecord::RecordInvalid.new(Connection.new)
            end

            # Add numeric suffix to letter
            params = params.dup
            params[:letter] = "#{letter}-#{attempt}"
          else
            raise
          end
        end
      end
    end

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
