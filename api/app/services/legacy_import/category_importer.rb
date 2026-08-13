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

        # Reject if group_id is NULL
        if row["group_id"].nil?
          skipped_invalid << { legacy_id:, reason: "group_id não pode ser nulo" }
          next
        end

        group = GROUP_MAP[row["group_id"]] || "temporario"

        taxa = taxas_by_id[row["taxasId"]&.to_i]
        next (skipped_invalid << { legacy_id:, reason: "taxa não encontrada: #{row['taxasId']}" }) if taxa.nil?

        has_water_meter = row["nome"].to_s.downcase.include?("hidrômetro") || row["nome"].to_s.downcase.include?("hidrometro")

        name = row["nome"]
        category = create_with_unique_name(
          name:,
          description: row["descricao"],
          group:,
          has_water_meter:,
          membership_price: (taxa["valor_socio"] || "0").to_d,
          water_price: (taxa["valor"] || "0").to_d,
          legacy_id:,
        )
        imported << category
      rescue ActiveRecord::RecordInvalid => e
        skipped_invalid << { legacy_id:, reason: e.message }
      end

      Result.new(imported: imported.size, skipped_duplicates: skipped_duplicates.size, skipped_invalid:)
    end

    private

    def create_with_unique_name(params)
      original_name = params[:name]
      attempt = 0
      max_attempts = 100

      loop do
        begin
          category = Category.new(**params)
          category.save!(validate: false)
          return category
        rescue ActiveRecord::RecordNotUnique => e
          # Check if it's the group+name unique constraint
          if e.message.include?("group") && e.message.include?("name")
            attempt += 1
            if attempt > max_attempts
              raise ActiveRecord::RecordInvalid.new(Category.new)
            end

            # Add numeric suffix to name
            params = params.dup
            params[:name] = "#{original_name} -#{attempt}"
          else
            raise
          end
        end
      end
    end
  end
end
