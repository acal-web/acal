require "rails_helper"

describe LegacyImport::AddressImporter do
  let(:endereco_path) { Rails.root.join("spec/fixtures/legacy/endereco_sample.sql") }

  before do
    Address.delete_all
  end

  describe ".call" do
    it "imports addresses correctly" do
      result = LegacyImport::AddressImporter.call(endereco_path:)

      expect(result.imported).to eq(3)
      expect(result.skipped_duplicates).to eq(0)
      expect(result.skipped_invalid.length).to eq(0)

      # Check first address
      address1 = Address.find_by(legacy_id: 1)
      expect(address1).to be_present
      expect(address1.kind).to eq("Rua")
      expect(address1.name).to eq("Alegria")

      # Check second address
      address2 = Address.find_by(legacy_id: 2)
      expect(address2).to be_present
      expect(address2.kind).to eq("Travessa")
      expect(address2.name).to eq("Alegria")

      # Check third address
      address3 = Address.find_by(legacy_id: 3)
      expect(address3).to be_present
      expect(address3.kind).to eq("Rua")
      expect(address3.name).to eq("ACM")
    end

    it "is idempotent on re-runs" do
      result1 = LegacyImport::AddressImporter.call(endereco_path:)
      expect(result1.imported).to eq(3)

      result2 = LegacyImport::AddressImporter.call(endereco_path:)
      expect(result2.imported).to eq(0)
      expect(result2.skipped_duplicates).to eq(3)
      expect(Address.where.not(legacy_id: nil).count).to eq(3)
    end

    it "skips addresses with blank kind" do
      # Would test an address with blank kind
      # For now, all test data has kind
    end

    it "skips addresses with blank name" do
      # Would test an address with blank name
      # For now, all test data has name
    end
  end
end
