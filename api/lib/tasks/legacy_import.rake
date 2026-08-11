namespace :legacy_import do
  desc "Importa categorias legadas a partir de dumps MySQL"
  task categories: :environment do
    categoria_path = ENV.fetch("CATEGORIA_SQL_PATH") { abort "CATEGORIA_SQL_PATH é obrigatório" }
    taxa_path = ENV.fetch("TAXA_SQL_PATH") { abort "TAXA_SQL_PATH é obrigatório" }

    puts "Iniciando importação de categorias..."
    puts "  Categorias: #{categoria_path}"
    puts "  Taxas: #{taxa_path}"
    puts

    result = LegacyImport::CategoryImporter.call(categoria_path:, taxa_path:)

    puts "Importação concluída!"
    puts "  Importadas: #{result.imported}"
    puts "  Puladas (já existentes): #{result.skipped_duplicates}"

    if result.skipped_invalid.any?
      puts "  Puladas (inválidas):"
      result.skipped_invalid.each do |entry|
        puts "    legacy_id=#{entry[:legacy_id]}: #{entry[:reason]}"
      end
    end
  end

  desc "Importa customers legados a partir de dumps MySQL"
  task customers: :environment do
    pessoa_path = ENV.fetch("PESSOA_SQL_PATH") { abort "PESSOA_SQL_PATH é obrigatório" }

    puts "Iniciando importação de customers..."
    puts "  Pessoas: #{pessoa_path}"
    puts

    result = LegacyImport::CustomerImporter.call(pessoa_path:)

    puts "Importação concluída!"
    puts "  Importadas: #{result.imported}"
    puts "  Puladas (já existentes): #{result.skipped_duplicates}"

    if result.skipped_invalid.any?
      puts "  Puladas (inválidas):"
      result.skipped_invalid.each do |entry|
        puts "    legacy_id=#{entry[:legacy_id]}: #{entry[:reason]}"
      end
    end
  end

  desc "Importa endereços legados a partir de dumps MySQL"
  task addresses: :environment do
    endereco_path = ENV.fetch("ENDERECO_SQL_PATH") { abort "ENDERECO_SQL_PATH é obrigatório" }

    puts "Iniciando importação de endereços..."
    puts "  Endereços: #{endereco_path}"
    puts

    result = LegacyImport::AddressImporter.call(endereco_path:)

    puts "Importação concluída!"
    puts "  Importados: #{result.imported}"
    puts "  Pulados (já existentes): #{result.skipped_duplicates}"

    if result.skipped_invalid.any?
      puts "  Pulados (inválidos):"
      result.skipped_invalid.each do |entry|
        puts "    legacy_id=#{entry[:legacy_id]}: #{entry[:reason]}"
      end
    end
  end

  desc "Importa análises de qualidade legadas a partir de dumps MySQL"
  task quality_analyses: :environment do
    tipo_parametro_path = ENV.fetch("TIPO_PARAMETRO_SQL_PATH") { abort "TIPO_PARAMETRO_SQL_PATH é obrigatório" }
    parametro_coleta_path = ENV.fetch("PARAMETRO_COLETA_SQL_PATH") { abort "PARAMETRO_COLETA_SQL_PATH é obrigatório" }

    puts "Iniciando importação de análises de qualidade..."
    puts "  Tipos de Parâmetro: #{tipo_parametro_path}"
    puts "  Parâmetros de Coleta: #{parametro_coleta_path}"
    puts

    result = LegacyImport::QualityAnalysisImporter.call(
      tipo_parametro_path:,
      parametro_coleta_path:
    )

    puts "Importação concluída!"
    puts "  Importadas: #{result.imported}"
    puts "  Puladas (já existentes): #{result.skipped_duplicates}"

    if result.skipped_invalid.any?
      puts "  Puladas (inválidas):"
      result.skipped_invalid.each do |entry|
        puts "    legacy_id=#{entry[:legacy_id]}: #{entry[:reason]}"
      end
    end
  end
end
