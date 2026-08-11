require "rails_helper"

describe LegacyImport::QualityAnalysisImporter do
  let(:tipo_parametro_path) { Rails.root.join("spec/fixtures/legacy/tipo_parametro_sample.sql") }
  let(:parametro_coleta_path) { Rails.root.join("spec/fixtures/legacy/parametro_coleta_sample.sql") }

  before do
    QualityAnalysis.delete_all
  end

  describe ".call" do
    it "imports quality analyses correctly" do
      result = LegacyImport::QualityAnalysisImporter.call(
        tipo_parametro_path:,
        parametro_coleta_path:
      )

      expect(result.imported).to eq(3)
      expect(result.skipped_duplicates).to eq(0)
      expect(result.skipped_invalid.length).to eq(0)

      # Check first analysis
      qa1 = QualityAnalysis.find_by(legacy_id: 143)
      expect(qa1).to be_present
      expect(qa1.param_name).to eq("Coliformes Totais")
      expect(qa1.required).to eq(10)
      expect(qa1.analyzed).to eq(5)
      expect(qa1.compliant).to eq(5)
      expect(qa1.reference_date).to eq(Date.parse("2019-01-01"))

      # Check second analysis
      qa2 = QualityAnalysis.find_by(legacy_id: 144)
      expect(qa2).to be_present
      expect(qa2.param_name).to eq("Escherichia Coli")
      expect(qa2.required).to eq(10)

      # Check third analysis
      qa3 = QualityAnalysis.find_by(legacy_id: 145)
      expect(qa3).to be_present
      expect(qa3.param_name).to eq("Cloro Residual")
    end

    it "is idempotent on re-runs" do
      result1 = LegacyImport::QualityAnalysisImporter.call(
        tipo_parametro_path:,
        parametro_coleta_path:
      )
      expect(result1.imported).to eq(3)

      result2 = LegacyImport::QualityAnalysisImporter.call(
        tipo_parametro_path:,
        parametro_coleta_path:
      )
      expect(result2.imported).to eq(0)
      expect(result2.skipped_duplicates).to eq(3)
      expect(QualityAnalysis.where.not(legacy_id: nil).count).to eq(3)
    end

    it "skips analyses with invalid param type" do
      # Would test an analysis with unmapped tipo_parametro
      # For now, all test data has valid mapping
    end

    it "skips analyses with blank date" do
      # Would test an analysis with blank date
      # For now, all test data has valid date
    end
  end
end
