require "rails_helper"

RSpec.describe LegacyImport::CustomerImporter do
  describe ".call" do
    it "assigns a unique customer_code to an imported customer" do
      mock_dump_data([
        { "id" => "1", "nome" => "Fulano", "sobrenome" => "de Tal", "cpf" => "11144477735", "numeroMatricula" => "10" }
      ])

      result = described_class.call(pessoa_path: "dummy.sql")

      expect(result.imported).to eq(1)
      customer = Customer.find_by(legacy_id: 1)
      expect(customer.customer_code).to be_present
      expect(customer.customer_code).to match(/\A\d{6}\z/)
    end

    it "assigns different customer_codes to different customers in the same batch" do
      mock_dump_data([
        { "id" => "1", "nome" => "Fulano", "sobrenome" => "de Tal", "cpf" => "11144477735", "numeroMatricula" => "10" },
        { "id" => "2", "nome" => "Ciclano", "sobrenome" => "da Silva", "cpf" => "98765432100", "numeroMatricula" => "11" }
      ])

      described_class.call(pessoa_path: "dummy.sql")

      codes = Customer.where(legacy_id: [ 1, 2 ]).pluck(:customer_code)
      expect(codes.uniq.length).to eq(2)
    end

    it "never reuses a customer_code already taken by an existing customer" do
      existing = create(:customer, customer_code: "000001")
      allow_any_instance_of(described_class).to receive(:rand).with(1_000_000).and_return(1, 2)

      mock_dump_data([
        { "id" => "1", "nome" => "Fulano", "sobrenome" => "de Tal", "cpf" => "11144477735", "numeroMatricula" => "10" }
      ])

      described_class.call(pessoa_path: "dummy.sql")

      imported = Customer.find_by(legacy_id: 1)
      expect(imported.customer_code).not_to eq(existing.customer_code)
      expect(imported.customer_code).to eq("000002")
    end
  end

  private

  def mock_dump_data(rows)
    allow(LegacyImport::SqlDumpParser).to receive(:call) do |_path|
      {
        "pessoa" => Struct.new(:rows).new(rows)
      }
    end
  end
end
