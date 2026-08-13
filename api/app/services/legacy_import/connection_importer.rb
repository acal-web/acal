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

      existing_legacy_ids = Set.new(Connection.pluck(:legacy_id))
      customer_map = Customer.pluck(:legacy_id, :id).to_h
      address_map = Address.pluck(:legacy_id, :id).to_h
      category_map = Category.pluck(:legacy_id, :id).to_h

      imported = 0
      skipped_duplicates = 0
      skipped_invalid = []
      batch = []
      batch_size = 1000
      max_number = Connection.maximum(:number).to_i

      ligacoes.each do |row|
        legacy_id = row["id"].to_i

        if existing_legacy_ids.include?(legacy_id)
          skipped_duplicates += 1
          next
        end

        customer_id = customer_map[row["idPessoa"].to_i]
        unless customer_id
          skipped_invalid << { legacy_id:, reason: "Sócio não encontrado (idPessoa=#{row['idPessoa']})" }
          next
        end

        address_id = address_map[row["idEndereco"].to_i]
        unless address_id
          skipped_invalid << { legacy_id:, reason: "Endereço não encontrado (idEndereco=#{row['idEndereco']})" }
          next
        end

        category_id = category_map[row["idCategoriaSocio"].to_i]
        unless category_id
          skipped_invalid << { legacy_id:, reason: "Categoria não encontrada (idCategoriaSocio=#{row['idCategoriaSocio']})" }
          next
        end

        number, letter = parse_numero(row["Numero"])
        tags = []
        if number.nil? || number <= 0
          max_number += 1
          number = max_number
          tags << "invalid number"
        end

        active = !bit_true?(row["inativo"])
        exclusively_member = bit_true?(row["socioExclusivo"])
        membership_date = row["datamatricula"].presence || "2000-01-01"

        batch << {
          customer_id:,
          address_id:,
          category_id:,
          number:,
          letter:,
          active:,
          legacy_id:,
          membership_date:,
          exclusively_member:,
          tags:,
          created_at: Time.current,
          updated_at: Time.current
        }

        if batch.size >= batch_size
          imported += batch.size
          Connection.insert_all(batch, ignore_duplicates: true)
          batch = []
        end
      rescue StandardError => e
        skipped_invalid << { legacy_id:, reason: e.message }
      end

      # Insert remaining batch
      if batch.any?
        imported += batch.size
        Connection.insert_all(batch, ignore_duplicates: true)
      end

      Result.new(imported:, skipped_duplicates:, skipped_invalid:)
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
