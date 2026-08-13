require "rails_helper"

describe LegacyImport::CategoryImporter do
  let(:categoria_path) { Rails.root.join("spec/fixtures/legacy/categoriasocio_sample.sql") }
  let(:taxa_path) { Rails.root.join("spec/fixtures/legacy/taxa_sample.sql") }

  before do
    Category.delete_all
  end

  describe ".call" do
    it "imports categories with correct mappings" do
      result = LegacyImport::CategoryImporter.call(categoria_path:, taxa_path:)

      expect(result.imported).to eq(2)
      expect(result.skipped_duplicates).to eq(0)
      expect(result.skipped_invalid.length).to eq(1)

      normal = Category.find_by(legacy_id: 1)
      expect(normal).to be_present
      expect(normal.name).to eq("Normal")
      expect(normal.description).to eq("Regular member")
      expect(normal.group).to eq("efetivo")
      expect(normal.membership_price).to eq(BigDecimal("3.00"))
      expect(normal.water_price).to eq(BigDecimal("27.00"))

      founder = Category.find_by(legacy_id: 2)
      expect(founder).to be_present
      expect(founder.name).to eq("Founder")
      expect(founder.group).to eq("fundador")
      expect(founder.membership_price).to eq(BigDecimal("0"))
      expect(founder.water_price).to eq(BigDecimal("20.00"))
    end

    it "skips categories with NULL group_id" do
      result = LegacyImport::CategoryImporter.call(categoria_path:, taxa_path:)

      expect(result.skipped_invalid.length).to eq(1)
      skip_entry = result.skipped_invalid.first
      expect(skip_entry[:legacy_id]).to eq(3)
      expect(skip_entry[:reason]).to include("group_id")
    end

    it "detects has_water_meter based on 'Hidrometro' in category name" do
      LegacyImport::CategoryImporter.call(categoria_path:, taxa_path:)

      normal = Category.find_by(legacy_id: 1)
      expect(normal.has_water_meter).to be_falsey

      founder = Category.find_by(legacy_id: 2)
      expect(founder.has_water_meter).to be_falsey
    end

    it "detects Hidrometro case-insensitively" do
      # Create test fixtures with Hidrometro variations
      test_categoria_path = Rails.root.join("spec/fixtures/legacy/hidrometro_test.sql")
      File.write(test_categoria_path, 'CREATE TABLE `categoriasocio` (
        `id` int, `nome` varchar(255), `descricao` text, `taxasId` int, `group_id` bigint
      );
INSERT INTO `categoriasocio` VALUES (1,\'HIDROMETRO\',\'\',1,2),(2,\'Hidrometro Ativo\',\'\',1,2),(3,\'hidrometro inativo\',\'\',1,2),(4,\'Normal\',\'\',1,2);')

      begin
        LegacyImport::CategoryImporter.call(categoria_path: test_categoria_path, taxa_path:)

        expect(Category.find_by(legacy_id: 1).has_water_meter).to be_truthy
        expect(Category.find_by(legacy_id: 2).has_water_meter).to be_truthy
        expect(Category.find_by(legacy_id: 3).has_water_meter).to be_truthy
        expect(Category.find_by(legacy_id: 4).has_water_meter).to be_falsey
      ensure
        File.delete(test_categoria_path) if File.exist?(test_categoria_path)
        Category.where(legacy_id: [ 1, 2, 3, 4 ]).delete_all
      end
    end

    it "is idempotent on re-runs" do
      result1 = LegacyImport::CategoryImporter.call(categoria_path:, taxa_path:)
      expect(result1.imported).to eq(2)

      result2 = LegacyImport::CategoryImporter.call(categoria_path:, taxa_path:)
      expect(result2.imported).to eq(0)
      expect(result2.skipped_duplicates).to eq(2)
      expect(Category.where.not(legacy_id: nil).count).to eq(2)
    end

    it "maps group_id correctly (1=fundador, 2=efetivo, 3=temporario)" do
      LegacyImport::CategoryImporter.call(categoria_path:, taxa_path:)

      # From fixture: id 1 has group_id 2 (efetivo), id 2 has group_id 1 (fundador)
      expect(Category.find_by(legacy_id: 1).group).to eq("efetivo")
      expect(Category.find_by(legacy_id: 2).group).to eq("fundador")
    end

    it "defaults valor_outros to 0 when NULL" do
      LegacyImport::CategoryImporter.call(categoria_path:, taxa_path:)

      categories = Category.where.not(legacy_id: nil)
      expect(categories.all? { |c| c.water_price >= 0 }).to be_truthy
    end

    it "handles invalid categoria data gracefully" do
      # Test with an actual invalid scenario — this tests the rescue behavior
      # Create a temporary bad SQL file
      bad_categoria_path = Rails.root.join("spec/fixtures/legacy/bad_categoriasocio.sql")
      File.write(bad_categoria_path, 'CREATE TABLE `categoriasocio` (
        `id` int, `nome` varchar(255), `descricao` text, `taxasId` int, `group_id` bigint
      );
INSERT INTO `categoriasocio` VALUES (99,\'Bad\',\'\',999,2);')

      begin
        result = LegacyImport::CategoryImporter.call(categoria_path: bad_categoria_path, taxa_path:)

        expect(result.imported).to eq(0)
        expect(result.skipped_invalid.length).to eq(1)
        expect(result.skipped_invalid.first[:reason]).to include("taxa")
      ensure
        File.delete(bad_categoria_path) if File.exist?(bad_categoria_path)
      end
    end

    it "resolves name conflicts by adding numeric suffix" do
      # Create a temporary SQL file with duplicate names
      conflict_categoria_path = Rails.root.join("spec/fixtures/legacy/conflict_categoriasocio.sql")
      File.write(conflict_categoria_path, 'CREATE TABLE `categoriasocio` (
        `id` int, `nome` varchar(255), `descricao` text, `taxasId` int, `group_id` bigint
      );
INSERT INTO `categoriasocio` VALUES (1,\'Agua\',\'Water\',5,2),(2,\'Agua\',\'Water Duplicate\',5,2);')

      begin
        result = LegacyImport::CategoryImporter.call(categoria_path: conflict_categoria_path, taxa_path:)

        expect(result.imported).to eq(2)
        cat1 = Category.find_by(legacy_id: 1)
        cat2 = Category.find_by(legacy_id: 2)
        expect(cat1).to be_present
        expect(cat2).to be_present
        expect(cat1.name).to eq("Agua")
        expect(cat2.name).to match(/^Agua -\d+$/)  # Should be "Agua -1" or similar
        expect(cat1.group).to eq(cat2.group)  # Same group
      ensure
        File.delete(conflict_categoria_path) if File.exist?(conflict_categoria_path)
        Category.where(legacy_id: [ 1, 2 ]).delete_all
      end
    end
  end
end
