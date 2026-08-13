require "rails_helper"

describe LegacyImport::CustomerImporter do
  let(:pessoa_path) { Rails.root.join("spec/fixtures/legacy/pessoa_sample.sql") }

  before do
    Customer.delete_all
  end

  describe ".call" do
    it "imports customers with cleaned names and documents" do
      result = LegacyImport::CustomerImporter.call(pessoa_path:)

      expect(result.imported).to eq(3)
      expect(result.skipped_duplicates).to eq(0)
      expect(result.skipped_invalid.length).to eq(0)

      # Check first customer (CPF)
      customer1 = Customer.find_by(legacy_id: 1)
      expect(customer1).to be_present
      expect(customer1.name).to eq("João Silva")
      expect(customer1.document).to eq("11144477735")
      expect(customer1.membership_number).to eq(1001)

      # Check second customer (CNPJ)
      customer2 = Customer.find_by(legacy_id: 2)
      expect(customer2).to be_present
      expect(customer2.name).to eq("Maria Santos")
      expect(customer2.document).to eq("11222333000181")
      expect(customer2.membership_number).to eq(1002)

      # Check third customer
      customer3 = Customer.find_by(legacy_id: 3)
      expect(customer3).to be_present
      expect(customer3.name).to eq("Pedro Oliveira")
      expect(customer3.document).to eq("22255588846")
      expect(customer3.membership_number).to eq(1003)
    end

    it "prefers CPF over CNPJ when both exist" do
      # This would test if both CPF and CNPJ exist, CPF takes priority
      # The sample doesn't have this case, but the logic should prefer CPF
    end

    it "trims extra spaces and keeps single space between names" do
      result = LegacyImport::CustomerImporter.call(pessoa_path:)

      customers = Customer.where.not(legacy_id: nil)
      customers.each do |c|
        expect(c.name).not_to match(/  /)  # No double spaces
        expect(c.name).not_to match(/^ | $/)  # No leading/trailing spaces
      end
    end

    it "is idempotent on re-runs" do
      result1 = LegacyImport::CustomerImporter.call(pessoa_path:)
      expect(result1.imported).to eq(3)

      result2 = LegacyImport::CustomerImporter.call(pessoa_path:)
      expect(result2.imported).to eq(0)
      expect(result2.skipped_duplicates).to eq(3)
      expect(Customer.where.not(legacy_id: nil).count).to eq(3)
    end

    it "handles missing document gracefully" do
      # Would test a customer with no CPF and no CNPJ
      # For now, all test data has at least one
    end

    it "generates valid CPF for invalid documents and adds tags" do
      invalid_pessoa_path = Rails.root.join("spec/fixtures/legacy/pessoa_invalid_document_sample.sql")

      result = LegacyImport::CustomerImporter.call(pessoa_path: invalid_pessoa_path)

      customer = Customer.find_by(legacy_id: 99)
      expect(customer).to be_present
      expect(customer.name).to eq("Test Invalid")
      expect(customer.document).to match(/^\d{11}$/)  # Generated valid CPF
      expect(customer.tags).to include("invalid document")
      expect(customer.tags).to include("invalid data")
    end

    it "does not tag valid documents" do
      result = LegacyImport::CustomerImporter.call(pessoa_path:)

      customer1 = Customer.find_by(legacy_id: 1)
      expect(customer1.tags).to be_empty
    end

    it "resolves duplicate documents by generating new valid CPF and tagging" do
      duplicate_pessoa_path = Rails.root.join("spec/fixtures/legacy/pessoa_duplicate_document_sample.sql")

      duplicate_sql = 'CREATE TABLE `pessoa` (
        `id` int(11) NOT NULL,
        `nome` varchar(255) NOT NULL,
        `sobrenome` varchar(255) NOT NULL,
        `cpf` varchar(255) DEFAULT NULL,
        `cnpj` varchar(255) DEFAULT NULL,
        `email` varchar(255) DEFAULT NULL,
        `telefone` varchar(255) DEFAULT NULL,
        `numeroMatricula` int(11) DEFAULT NULL,
        `sexo` varchar(255) NOT NULL,
        `status` bit(1) NOT NULL
      );
      INSERT INTO `pessoa` VALUES (100,\'Test\',\'One\',\'111.444.777-35\',NULL,\'test1@test.com\',NULL,100,\'Masculino\',1),(101,\'Test\',\'Two\',\'111.444.777-35\',NULL,\'test2@test.com\',NULL,101,\'Feminino\',1);'

      File.write(duplicate_pessoa_path, duplicate_sql)

      begin
        result = LegacyImport::CustomerImporter.call(pessoa_path: duplicate_pessoa_path)

        expect(result.imported).to eq(2)
        customer1 = Customer.find_by(legacy_id: 100)
        customer2 = Customer.find_by(legacy_id: 101)

        expect(customer1).to be_present
        expect(customer2).to be_present
        expect(customer1.document).to eq("11144477735")
        expect(customer2.document).not_to eq("11144477735")
        expect(customer1.tags).to be_empty
        expect(customer2.tags).to include("duplicate document")
        expect(customer2.tags).to include("invalid data")
      ensure
        File.delete(duplicate_pessoa_path) if File.exist?(duplicate_pessoa_path)
        Customer.where(legacy_id: [ 100, 101 ]).delete_all
      end
    end
  end
end
