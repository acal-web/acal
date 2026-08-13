module LegacyImport
  class InvoiceImporter
    Result = Struct.new(:imported, :skipped_duplicates, :skipped_invalid, keyword_init: true)

    def self.call(conta_path:)
      new(conta_path).call
    end

    def initialize(conta_path)
      @conta_path = conta_path
    end

    def call
      contas = SqlDumpParser.call(@conta_path).fetch("conta").rows

      existing_legacy_ids = Set.new(Invoice.pluck(:legacy_id))
      connection_map = Connection.pluck(:legacy_id, :id).to_h
      existing_period_keys = Invoice.pluck(:connection_id, :reference_date, :legacy_id)
        .each_with_object({}) { |(connection_id, reference_date, legacy_id), memo|
          memo[[ connection_id, reference_date ]] = legacy_id
        }

      imported = 0
      skipped_duplicates = 0
      skipped_invalid = []
      batch = []
      batch_size = 1000

      contas.each do |row|
        legacy_id = row["id"].to_i

        if existing_legacy_ids.include?(legacy_id)
          skipped_duplicates += 1
          next
        end

        connection_id = connection_map[row["idEnderecoPessoa"].to_i]
        unless connection_id
          skipped_invalid << { legacy_id:, reason: "Ligação não encontrada (idEnderecoPessoa=#{row['idEnderecoPessoa']})" }
          next
        end

        if row["dataReferente"].blank?
          skipped_invalid << { legacy_id:, reason: "Data de referência vazia" }
          next
        end
        reference_date = Date.parse(row["dataReferente"])

        if row["dataVence"].blank?
          skipped_invalid << { legacy_id:, reason: "Data de vencimento vazia" }
          next
        end

        membership_value = (row["ValorTaxa"] || "0").to_d
        water_value = (row["ValorOutros"] || "0").to_d

        if membership_value.negative?
          skipped_invalid << { legacy_id:, reason: "Valor de taxa negativo (ValorTaxa=#{membership_value})" }
          next
        end

        if water_value.negative?
          skipped_invalid << { legacy_id:, reason: "Valor de água negativo (ValorOutros=#{water_value})" }
          next
        end

        period_key = [ connection_id, reference_date ]
        if (winner_legacy_id = existing_period_keys[period_key])
          skipped_invalid << { legacy_id:, reason: "Fatura duplicada para esta ligação e período (connection_id=#{connection_id}, reference_date=#{reference_date}); mantida legacy_id=#{winner_legacy_id}" }
          next
        end

        batch << {
          connection_id:,
          reference_date:,
          due_date: row["dataVence"],
          paid_at: row["dataPag"],
          membership_value:,
          water_value:,
          legacy_id:,
          created_at: Time.current,
          updated_at: Time.current
        }
        existing_period_keys[period_key] = legacy_id

        if batch.size >= batch_size
          imported += batch.size
          Invoice.insert_all(batch)
          batch = []
        end
      rescue StandardError => e
        skipped_invalid << { legacy_id:, reason: e.message }
      end

      # Insert remaining batch
      if batch.any?
        imported += batch.size
        Invoice.insert_all(batch)
      end

      Result.new(imported:, skipped_duplicates:, skipped_invalid:)
    end
  end
end
