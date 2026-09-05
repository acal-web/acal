require "rails_helper"

RSpec.describe LegacyImport::ConnectionImporter do
  let(:customer) { create(:customer, legacy_id: 1) }
  let(:address) { create(:address, legacy_id: 1) }
  let(:category) { create(:category, legacy_id: 1) }

  before do
    customer
    address
    category
  end

  describe ".call" do
    it "imports a single valid connection" do
      mock_dump_data([
        { "id" => "100", "idPessoa" => "1", "idEndereco" => "1", "idCategoriaSocio" => "1",
          "Numero" => "10", "inativo" => "\x00", "socioExclusivo" => "\x00", "datamatricula" => "2020-05-01" }
      ])

      result = described_class.call(ligacao_path: "dummy.sql")

      expect(result.imported).to eq(1)
      expect(result.skipped_duplicates).to eq(0)
      expect(result.skipped_invalid).to be_empty

      connection = Connection.find_by(legacy_id: 100)
      expect(connection).not_to be_nil
      expect(connection.customer_id).to eq(customer.id)
      expect(connection.address_id).to eq(address.id)
      expect(connection.category_id).to eq(category.id)
      expect(connection.number).to eq(10)
      expect(connection.letter).to be_nil
      expect(connection.active).to be(true)
      expect(connection.exclusively_member).to be(false)
      expect(connection.membership_date).to eq(Date.new(2020, 5, 1))
    end

    it "splits a number+letter Numero field (e.g. '10 A')" do
      mock_dump_data([
        { "id" => "101", "idPessoa" => "1", "idEndereco" => "1", "idCategoriaSocio" => "1", "Numero" => "10 A" }
      ])

      described_class.call(ligacao_path: "dummy.sql")

      connection = Connection.find_by(legacy_id: 101)
      expect(connection.number).to eq(10)
      expect(connection.letter).to eq("A")
    end

    it "marks inativo bit as an inactive connection" do
      mock_dump_data([
        { "id" => "102", "idPessoa" => "1", "idEndereco" => "1", "idCategoriaSocio" => "1", "Numero" => "10", "inativo" => "\x01" }
      ])

      described_class.call(ligacao_path: "dummy.sql")

      expect(Connection.find_by(legacy_id: 102).active).to be(false)
    end

    it "marks socioExclusivo bit as exclusively_member" do
      mock_dump_data([
        { "id" => "103", "idPessoa" => "1", "idEndereco" => "1", "idCategoriaSocio" => "1", "Numero" => "10", "socioExclusivo" => "\x01" }
      ])

      described_class.call(ligacao_path: "dummy.sql")

      expect(Connection.find_by(legacy_id: 103).exclusively_member).to be(true)
    end

    it "defaults membership_date to 2000-01-01 when blank" do
      mock_dump_data([
        { "id" => "104", "idPessoa" => "1", "idEndereco" => "1", "idCategoriaSocio" => "1", "Numero" => "10", "datamatricula" => nil }
      ])

      described_class.call(ligacao_path: "dummy.sql")

      expect(Connection.find_by(legacy_id: 104).membership_date).to eq(Date.new(2000, 1, 1))
    end

    it "assigns the next sequential number and tags it when Numero is blank or non-positive" do
      create(:connection, customer: customer, address: create(:address), category: category, number: 50)

      mock_dump_data([
        { "id" => "105", "idPessoa" => "1", "idEndereco" => "1", "idCategoriaSocio" => "1", "Numero" => "0" }
      ])

      described_class.call(ligacao_path: "dummy.sql")

      connection = Connection.find_by(legacy_id: 105)
      expect(connection.number).to eq(51)
      expect(connection.tags).to include("invalid number")
    end

    it "skips duplicate legacy_ids" do
      create(:connection, customer: customer, address: address, category: category, legacy_id: 100)
      mock_dump_data([
        { "id" => "100", "idPessoa" => "1", "idEndereco" => "1", "idCategoriaSocio" => "1", "Numero" => "10" }
      ])

      result = described_class.call(ligacao_path: "dummy.sql")

      expect(result.imported).to eq(0)
      expect(result.skipped_duplicates).to eq(1)
    end

    it "skips rows referencing a customer that wasn't imported" do
      mock_dump_data([
        { "id" => "106", "idPessoa" => "999", "idEndereco" => "1", "idCategoriaSocio" => "1", "Numero" => "10" }
      ])

      result = described_class.call(ligacao_path: "dummy.sql")

      expect(result.imported).to eq(0)
      expect(result.skipped_invalid.first[:reason]).to include("Sócio não encontrado")
    end

    it "skips rows referencing an address that wasn't imported" do
      mock_dump_data([
        { "id" => "107", "idPessoa" => "1", "idEndereco" => "999", "idCategoriaSocio" => "1", "Numero" => "10" }
      ])

      result = described_class.call(ligacao_path: "dummy.sql")

      expect(result.imported).to eq(0)
      expect(result.skipped_invalid.first[:reason]).to include("Endereço não encontrado")
    end

    it "skips rows referencing a category that wasn't imported" do
      mock_dump_data([
        { "id" => "108", "idPessoa" => "1", "idEndereco" => "1", "idCategoriaSocio" => "999", "Numero" => "10" }
      ])

      result = described_class.call(ligacao_path: "dummy.sql")

      expect(result.imported).to eq(0)
      expect(result.skipped_invalid.first[:reason]).to include("Categoria não encontrada")
    end
  end

  private

  def mock_dump_data(rows)
    allow(LegacyImport::SqlDumpParser).to receive(:call) do |_path|
      {
        "enderecopessoa" => Struct.new(:rows).new(rows)
      }
    end
  end
end
