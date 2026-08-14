require "rails_helper"

RSpec.describe LegacyImport::InvoiceImporter do
  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category) }
  let(:connection) { create(:connection, customer: customer, address: address, category: category, legacy_id: 1) }

  describe ".call" do
    it "imports a single valid invoice" do
      mock_dump_data([
        { "id" => "100", "idEnderecoPessoa" => "1", "dataReferente" => "2026-08-01", "dataVence" => "2026-08-10", "dataPag" => nil, "ValorTaxa" => "10.00", "ValorOutros" => "5.00" }
      ])

      result = described_class.call(conta_path: "dummy.sql")

      expect(result.imported).to eq(1)
      expect(result.skipped_duplicates).to eq(0)
      expect(result.skipped_invalid).to be_empty

      invoice = Invoice.find_by(legacy_id: 100)
      expect(invoice).not_to be_nil
      expect(invoice.connection_id).to eq(connection.id)
      expect(invoice.reference_date).to eq(Date.new(2026, 8, 1))
      expect(invoice.due_date).to eq(Date.new(2026, 8, 10))
      expect(invoice.membership_value).to eq(10.0)
      expect(invoice.water_value).to eq(5.0)
      expect(invoice.paid_at).to be_nil
    end

    it "skips duplicate legacy_ids" do
      create(:invoice, legacy_id: 100, connection: connection)
      mock_dump_data([
        { "id" => "100", "idEnderecoPessoa" => "1", "dataReferente" => "2026-08-01", "dataVence" => "2026-08-10", "dataPag" => nil, "ValorTaxa" => "10.00", "ValorOutros" => "5.00" }
      ])

      result = described_class.call(conta_path: "dummy.sql")

      expect(result.imported).to eq(0)
      expect(result.skipped_duplicates).to eq(1)
      expect(result.skipped_invalid).to be_empty
    end

    it "skips invoices with missing connection (FK)" do
      mock_dump_data([
        { "id" => "101", "idEnderecoPessoa" => "999", "dataReferente" => "2026-08-01", "dataVence" => "2026-08-10", "dataPag" => nil, "ValorTaxa" => "10.00", "ValorOutros" => "5.00" }
      ])

      result = described_class.call(conta_path: "dummy.sql")

      expect(result.imported).to eq(0)
      expect(result.skipped_duplicates).to eq(0)
      expect(result.skipped_invalid.length).to eq(1)
      expect(result.skipped_invalid.first[:reason]).to include("Ligação não encontrada")
    end

    it "skips invoices with blank required date fields" do
      mock_dump_data([
        { "id" => "102", "idEnderecoPessoa" => "1", "dataReferente" => nil, "dataVence" => "2026-08-10", "dataPag" => nil, "ValorTaxa" => "10.00", "ValorOutros" => "5.00" }
      ])

      result = described_class.call(conta_path: "dummy.sql")

      expect(result.imported).to eq(0)
      expect(result.skipped_invalid.length).to eq(1)
      expect(result.skipped_invalid.first[:reason]).to include("Data de referência vazia")
    end

    it "skips invoices with negative amounts" do
      mock_dump_data([
        { "id" => "103", "idEnderecoPessoa" => "1", "dataReferente" => "2026-08-01", "dataVence" => "2026-08-10", "dataPag" => nil, "ValorTaxa" => "-5.00", "ValorOutros" => "5.00" }
      ])

      result = described_class.call(conta_path: "dummy.sql")

      expect(result.imported).to eq(0)
      expect(result.skipped_invalid.length).to eq(1)
      expect(result.skipped_invalid.first[:reason]).to include("taxa negativo")
    end

    it "detects duplicate period keys (same connection + reference_date) and reports the first as winner" do
      other_connection = create(:connection, customer: create(:customer), address: create(:address), category: category, legacy_id: 2)

      mock_dump_data(
        [
          { "id" => "104", "idEnderecoPessoa" => "1", "dataReferente" => "2026-08-01", "dataVence" => "2026-08-10", "dataPag" => nil, "ValorTaxa" => "10.00", "ValorOutros" => "5.00" },
          { "id" => "105", "idEnderecoPessoa" => "1", "dataReferente" => "2026-08-01", "dataVence" => "2026-08-10", "dataPag" => nil, "ValorTaxa" => "15.00", "ValorOutros" => "5.00" },
          { "id" => "106", "idEnderecoPessoa" => "2", "dataReferente" => "2026-08-01", "dataVence" => "2026-08-10", "dataPag" => nil, "ValorTaxa" => "10.00", "ValorOutros" => "5.00" }
        ],
        { 2 => other_connection.id }
      )

      result = described_class.call(conta_path: "dummy.sql")

      expect(result.imported).to eq(2) # 104 and 106 only
      expect(result.skipped_duplicates).to eq(0)
      expect(result.skipped_invalid.length).to eq(1)
      expect(result.skipped_invalid.first[:legacy_id]).to eq(105)
      expect(result.skipped_invalid.first[:reason]).to include("Fatura duplicada")
      expect(result.skipped_invalid.first[:reason]).to include("legacy_id=104")

      # Verify the unrelated row 106 is actually in the DB (not silently dropped)
      expect(Invoice.find_by(legacy_id: 106)).not_to be_nil
    end
  end

  private

  def mock_dump_data(rows, extra_connections = {})
    allow(LegacyImport::SqlDumpParser).to receive(:call) do |_path|
      {
        "conta" => Struct.new(:rows).new(rows)
      }
    end
    # Mock pluck to return all connections known in this test context
    all_connections = { connection.legacy_id => connection.id }.merge(extra_connections)
    allow(Connection).to receive(:pluck).with(:legacy_id, :id).and_return(
      all_connections.map { |k, v| [ k, v ] }
    )
  end
end
