require "rails_helper"

RSpec.describe LegacyImport::InvoiceImporter do
  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category) }
  let(:connection) { create(:connection, customer: customer, address: address, category: category, legacy_id: 1) }

  describe ".call" do
    it "imports a single valid invoice" do
      sql_path = fixture_path("invoices_valid.sql")
      File.write(sql_path, <<~SQL)
        CREATE TABLE `conta` (
          `id` int(11),
          `dataGerada` datetime,
          `dataPag` datetime,
          `dataVence` datetime,
          `observacoes` text,
          `idEnderecoPessoa` int(11),
          `ValorTaxa` decimal(10,2),
          `ValorOutros` decimal(10,2),
          `SocioExclusivo` bit(1),
          `dataReferente` date,
          `versao` bigint(20)
        );
        INSERT INTO `conta` VALUES (100, '2026-08-01 10:00:00', NULL, '2026-08-10 00:00:00', NULL, 1, 10.00, 5.00, '\\0', '2026-08-01', 1);
      SQL

      result = described_class.call(conta_path: sql_path)

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
    ensure
      File.delete(sql_path) if File.exist?(sql_path)
    end

    it "skips duplicate legacy_ids" do
      create(:invoice, legacy_id: 100, connection: connection)
      sql_path = fixture_path("invoices_duplicate.sql")
      File.write(sql_path, <<~SQL)
        CREATE TABLE `conta` (
          `id` int(11),
          `dataGerada` datetime,
          `dataPag` datetime,
          `dataVence` datetime,
          `observacoes` text,
          `idEnderecoPessoa` int(11),
          `ValorTaxa` decimal(10,2),
          `ValorOutros` decimal(10,2),
          `SocioExclusivo` bit(1),
          `dataReferente` date,
          `versao` bigint(20)
        );
        INSERT INTO `conta` VALUES (100, '2026-08-01 10:00:00', NULL, '2026-08-10 00:00:00', NULL, 1, 10.00, 5.00, '\\0', '2026-08-01', 1);
      SQL

      result = described_class.call(conta_path: sql_path)

      expect(result.imported).to eq(0)
      expect(result.skipped_duplicates).to eq(1)
      expect(result.skipped_invalid).to be_empty
    ensure
      File.delete(sql_path) if File.exist?(sql_path)
    end

    it "skips invoices with missing connection (FK)" do
      sql_path = fixture_path("invoices_missing_fk.sql")
      File.write(sql_path, <<~SQL)
        CREATE TABLE `conta` (
          `id` int(11),
          `dataGerada` datetime,
          `dataPag` datetime,
          `dataVence` datetime,
          `observacoes` text,
          `idEnderecoPessoa` int(11),
          `ValorTaxa` decimal(10,2),
          `ValorOutros` decimal(10,2),
          `SocioExclusivo` bit(1),
          `dataReferente` date,
          `versao` bigint(20)
        );
        INSERT INTO `conta` VALUES (101, '2026-08-01 10:00:00', NULL, '2026-08-10 00:00:00', NULL, 999, 10.00, 5.00, '\\0', '2026-08-01', 1);
      SQL

      result = described_class.call(conta_path: sql_path)

      expect(result.imported).to eq(0)
      expect(result.skipped_duplicates).to eq(0)
      expect(result.skipped_invalid.length).to eq(1)
      expect(result.skipped_invalid.first[:reason]).to include("Ligação não encontrada")
    ensure
      File.delete(sql_path) if File.exist?(sql_path)
    end

    it "skips invoices with blank required date fields" do
      sql_path = fixture_path("invoices_blank_dates.sql")
      File.write(sql_path, <<~SQL)
        CREATE TABLE `conta` (
          `id` int(11),
          `dataGerada` datetime,
          `dataPag` datetime,
          `dataVence` datetime,
          `observacoes` text,
          `idEnderecoPessoa` int(11),
          `ValorTaxa` decimal(10,2),
          `ValorOutros` decimal(10,2),
          `SocioExclusivo` bit(1),
          `dataReferente` date,
          `versao` bigint(20)
        );
        INSERT INTO `conta` VALUES (102, '2026-08-01 10:00:00', NULL, '2026-08-10 00:00:00', NULL, 1, 10.00, 5.00, '\\0', NULL, 1);
      SQL

      result = described_class.call(conta_path: sql_path)

      expect(result.imported).to eq(0)
      expect(result.skipped_invalid.length).to eq(1)
      expect(result.skipped_invalid.first[:reason]).to include("Data de referência vazia")
    ensure
      File.delete(sql_path) if File.exist?(sql_path)
    end

    it "skips invoices with negative amounts" do
      sql_path = fixture_path("invoices_negative.sql")
      File.write(sql_path, <<~SQL)
        CREATE TABLE `conta` (
          `id` int(11),
          `dataGerada` datetime,
          `dataPag` datetime,
          `dataVence` datetime,
          `observacoes` text,
          `idEnderecoPessoa` int(11),
          `ValorTaxa` decimal(10,2),
          `ValorOutros` decimal(10,2),
          `SocioExclusivo` bit(1),
          `dataReferente` date,
          `versao` bigint(20)
        );
        INSERT INTO `conta` VALUES (103, '2026-08-01 10:00:00', NULL, '2026-08-10 00:00:00', NULL, 1, -5.00, 5.00, '\\0', '2026-08-01', 1);
      SQL

      result = described_class.call(conta_path: sql_path)

      expect(result.imported).to eq(0)
      expect(result.skipped_invalid.length).to eq(1)
      expect(result.skipped_invalid.first[:reason]).to include("taxa negativo")
    ensure
      File.delete(sql_path) if File.exist?(sql_path)
    end

    it "detects duplicate period keys (same connection + reference_date) and reports the first as winner" do
      sql_path = fixture_path("invoices_duplicate_periods.sql")
      File.write(sql_path, <<~SQL)
        CREATE TABLE `conta` (
          `id` int(11),
          `dataGerada` datetime,
          `dataPag` datetime,
          `dataVence` datetime,
          `observacoes` text,
          `idEnderecoPessoa` int(11),
          `ValorTaxa` decimal(10,2),
          `ValorOutros` decimal(10,2),
          `SocioExclusivo` bit(1),
          `dataReferente` date,
          `versao` bigint(20)
        );
        INSERT INTO `conta` VALUES
          (104, '2026-08-01 10:00:00', NULL, '2026-08-10 00:00:00', NULL, 1, 10.00, 5.00, '\\0', '2026-08-01', 1),
          (105, '2026-08-01 10:00:00', NULL, '2026-08-10 00:00:00', '2ª via', 1, 15.00, 5.00, '\\0', '2026-08-01', 1),
          (106, '2026-08-01 10:00:00', NULL, '2026-08-10 00:00:00', NULL, 2, 10.00, 5.00, '\\0', '2026-08-01', 1);
      SQL

      other_connection = create(:connection, customer: create(:customer), address: create(:address), category: category, legacy_id: 2)

      result = described_class.call(conta_path: sql_path)

      expect(result.imported).to eq(2) # 104 and 106 only
      expect(result.skipped_duplicates).to eq(0)
      expect(result.skipped_invalid.length).to eq(1)
      expect(result.skipped_invalid.first[:legacy_id]).to eq(105)
      expect(result.skipped_invalid.first[:reason]).to include("Fatura duplicada")
      expect(result.skipped_invalid.first[:reason]).to include("legacy_id=104")

      # Verify the unrelated row 106 is actually in the DB (not silently dropped)
      expect(Invoice.find_by(legacy_id: 106)).not_to be_nil
    ensure
      File.delete(sql_path) if File.exist?(sql_path)
    end
  end

  private

  def fixture_path(name)
    File.join(Dir.tmpdir, name)
  end
end
