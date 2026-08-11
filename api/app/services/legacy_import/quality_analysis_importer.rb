module LegacyImport
  class QualityAnalysisImporter
    PARAM_TYPE_MAP = {
      "1" => "Cor Aparente",
      "2" => "Turbidez",
      "3" => "Cloro Residual",
      "4" => "Escherichia Coli",
      "5" => "Coliformes Totais"
    }.freeze

    Result = Struct.new(:imported, :skipped_duplicates, :skipped_invalid, keyword_init: true)

    def self.call(tipo_parametro_path:, parametro_coleta_path:)
      new(tipo_parametro_path, parametro_coleta_path).call
    end

    def initialize(tipo_parametro_path, parametro_coleta_path)
      @tipo_parametro_path = tipo_parametro_path
      @parametro_coleta_path = parametro_coleta_path
    end

    def call
      # Parse tipo_parametro to build mapping
      tipo_parametro_rows = SqlDumpParser.call(@tipo_parametro_path).fetch("tipo_parametro").rows
      tipo_map = tipo_parametro_rows.index_by { |r| r["ide_tipo_parametro"].to_i }

      # Parse parametro_coleta
      parametro_coleta_rows = SqlDumpParser.call(@parametro_coleta_path).fetch("parametro_coleta").rows

      imported = []
      skipped_duplicates = []
      skipped_invalid = []

      parametro_coleta_rows.each do |row|
        legacy_id = row["ide_parametro_coleta"].to_i
        next (skipped_duplicates << legacy_id) if QualityAnalysis.exists?(legacy_id:)

        tipo_id = row["ide_tipo_parametro"]&.to_i
        param_name = PARAM_TYPE_MAP[tipo_id&.to_s]

        if param_name.blank?
          skipped_invalid << { legacy_id:, reason: "Tipo de parâmetro não mapeado: #{tipo_id}" }
          next
        end

        reference_date = row["data"]
        if reference_date.blank?
          skipped_invalid << { legacy_id:, reason: "Data vazia" }
          next
        end

        required = (row["exigido"] || "0").to_s.strip
        analyzed = (row["analisado"] || "0").to_s.strip
        compliant = (row["conformidade"] || "0").to_s.strip

        form = QualityAnalysisForm.new(
          param_name:,
          reference_date:,
          required:,
          analyzed:,
          compliant:,
          legacy_id:,
        )

        imported << QualityAnalysis.create!(**form.to_h)
      rescue ActiveRecord::RecordInvalid => e
        skipped_invalid << { legacy_id:, reason: e.message }
      end

      Result.new(imported: imported.size, skipped_duplicates: skipped_duplicates.size, skipped_invalid:)
    end
  end
end
