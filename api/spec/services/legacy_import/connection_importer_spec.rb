require "rails_helper"

describe LegacyImport::ConnectionImporter do
  let(:ligacao_path) { Rails.root.join("spec/fixtures/legacy/enderecopessoa_sample.sql") }

  before do
    Connection.delete_all
    Address.delete_all
    Customer.delete_all
    Category.delete_all

    # Create reference records matching the fixture
    @customer1 = create(:customer, legacy_id: 1)
    @customer2 = create(:customer, legacy_id: 2)
    @customer3 = create(:customer, legacy_id: 3)
    @customer4 = create(:customer, legacy_id: 4)
    @customer5 = create(:customer, legacy_id: 5)
    @customer6 = create(:customer, legacy_id: 6)
    @customer7 = create(:customer, legacy_id: 7)
    @customer8 = create(:customer, legacy_id: 8)

    @address1 = create(:address, legacy_id: 1)
    @address2 = create(:address, legacy_id: 2)
    @address3 = create(:address, legacy_id: 3)
    @address4 = create(:address, legacy_id: 4)

    @category1 = create(:category, legacy_id: 1)
    @category2 = create(:category, legacy_id: 2)
    @category3 = create(:category, legacy_id: 3)
    @category4 = create(:category, legacy_id: 4)
  end

  describe ".call" do
    it "imports connections with correct relationships and parsed numero/letter" do
      result = LegacyImport::ConnectionImporter.call(ligacao_path:)

      # id=1: valid (123 on address 1)
      # id=2: valid (456 on address 1 - different number, allowed)
      # id=3: valid (123 on address 1 - same number as id=1, but resolved with letter suffix "-1")
      # id=4: valid (no valid number, generates sequential) with tag "invalid number"
      # id=5: skipped (customer 99 doesn't exist)
      # id=6: skipped (address 99 doesn't exist)
      # id=7: skipped (category 99 doesn't exist)
      # id=8: valid (200 on address 1 - different number)
      # id=9: valid (123 on address 2 - different address, allowed)
      expect(result.imported).to eq(6) # 1, 2, 3, 4, 8, 9
      expect(result.skipped_duplicates).to eq(0)
      expect(result.skipped_invalid.size).to eq(3) # 5, 6, 7

      # Verify id=1: simple number, both bits false
      conn1 = Connection.find_by(legacy_id: 1)
      expect(conn1).to be_present
      expect(conn1.customer_id).to eq(@customer1.id)
      expect(conn1.address_id).to eq(@address1.id)
      expect(conn1.category_id).to eq(@category1.id)
      expect(conn1.number).to eq(123)
      expect(conn1.letter).to be_nil
      expect(conn1.active).to be true
      expect(conn1.exclusively_member).to be false
      expect(conn1.membership_date).to eq(Date.parse("2024-01-15"))

      # Verify id=2: different number on same address, socioExclusivo=true (0x01 in raw)
      conn2 = Connection.find_by(legacy_id: 2)
      expect(conn2).to be_present
      expect(conn2.number).to eq(456)
      expect(conn2.exclusively_member).to be true
    end

    it "is idempotent on re-runs" do
      result1 = LegacyImport::ConnectionImporter.call(ligacao_path:)
      expect(result1.imported).to eq(6)

      result2 = LegacyImport::ConnectionImporter.call(ligacao_path:)
      expect(result2.imported).to eq(0)
      expect(result2.skipped_duplicates).to eq(6)
      expect(Connection.where.not(legacy_id: nil).count).to eq(6)
    end

    it "generates sequential number for invalid numero and adds tag" do
      result = LegacyImport::ConnectionImporter.call(ligacao_path:)
      conn4 = Connection.find_by(legacy_id: 4)
      expect(conn4).to be_present
      expect(conn4.number).to be > 0  # Should have a sequential number
      expect(conn4.tags).to include("invalid number")
    end

    it "skips connections when referenced customer doesn't exist" do
      result = LegacyImport::ConnectionImporter.call(ligacao_path:)
      invalid = result.skipped_invalid.find { |e| e[:legacy_id] == 5 }
      expect(invalid).to be_present
      expect(invalid[:reason]).to match(/Sócio não encontrado/)
    end

    it "skips connections when referenced address doesn't exist" do
      result = LegacyImport::ConnectionImporter.call(ligacao_path:)
      invalid = result.skipped_invalid.find { |e| e[:legacy_id] == 6 }
      expect(invalid).to be_present
      expect(invalid[:reason]).to match(/Endereço não encontrado/)
    end

    it "skips connections when referenced category doesn't exist" do
      result = LegacyImport::ConnectionImporter.call(ligacao_path:)
      invalid = result.skipped_invalid.find { |e| e[:legacy_id] == 7 }
      expect(invalid).to be_present
      expect(invalid[:reason]).to match(/Categoria não encontrada/)
    end

    it "resolves number conflicts by adding letter suffix" do
      result = LegacyImport::ConnectionImporter.call(ligacao_path:)
      # id=1 (123 on address 1) imports successfully
      # id=3 (123 on address 1) also imports with modified letter to avoid conflict
      conn1 = Connection.find_by(legacy_id: 1)
      conn3 = Connection.find_by(legacy_id: 3)
      expect(conn1).to be_present
      expect(conn3).to be_present
      expect(conn1.number).to eq(123)
      expect(conn3.number).to eq(123)
      expect(conn1.letter).to be_nil
      expect(conn3.letter).to match(/^-\d+$/)  # Should be something like "-1"
    end

    it "allows multiple active connections on the same address when number differs" do
      result = LegacyImport::ConnectionImporter.call(ligacao_path:)
      # id=1 (123 on address 1) and id=2 (456 on address 1) both import
      conn1 = Connection.find_by(legacy_id: 1)
      conn2 = Connection.find_by(legacy_id: 2)
      expect(conn1).to be_present
      expect(conn2).to be_present
      expect(conn1.address_id).to eq(conn2.address_id)
      expect(conn1.number).to eq(123)
      expect(conn2.number).to eq(456)
    end

    it "correctly parses bit fields: false='\\0', true=raw 0x01 byte" do
      result = LegacyImport::ConnectionImporter.call(ligacao_path:)
      # Only id=1 passes, so just verify its bit parsing
      conn1 = Connection.find_by(legacy_id: 1)
      expect(conn1.active).to be true
      expect(conn1.exclusively_member).to be false
    end
  end
end
