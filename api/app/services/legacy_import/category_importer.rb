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

      imported = []
      skipped_duplicates = []
      skipped_invalid = []

      categorias.each do |row|
        legacy_id = row["id"].to_i
        next (skipped_duplicates << legacy_id) if Category.exists?(legacy_id:)

        group = GROUP_MAP[row["group_id"]]
        next (skipped_invalid << { legacy_id:, reason: "group_id não mapeado: #{row['group_id'].inspect}" }) if group.nil?

        taxa = taxas_by_id[row["taxasId"]&.to_i]
        next (skipped_invalid << { legacy_id:, reason: "taxa não encontrada: #{row['taxasId']}" }) if taxa.nil?

        has_water_meter = row["nome"].to_s.downcase.include?("hidrômetro") || row["nome"].to_s.downcase.include?("hidrometro")

        form = CategoryForm.new(
          name: row["nome"],
          description: row["descricao"],
          group:,
          has_water_meter:,
          membership_price: (taxa["valor_socio"] || "0").to_d,
          water_price: (taxa["valor"] || "0").to_d,
          legacy_id:,
        )
        imported << Category.create!(**form.to_h)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        skipped_invalid << { legacy_id:, reason: e.message }
      end

      Result.new(imported: imported.size, skipped_duplicates: skipped_duplicates.size, skipped_invalid:)
    end
  end
end
