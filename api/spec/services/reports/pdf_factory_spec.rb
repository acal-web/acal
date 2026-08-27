require "rails_helper"

RSpec.describe Reports::PdfFactory do
  describe ".build" do
    it "returns a Prawn document with the shared font registered" do
      pdf = described_class.build

      expect(pdf).to be_a(Prawn::Document)
      expect(pdf.font.family).to eq(described_class::FONT_NAME)
    end

    it "forwards extra options to Prawn::Document" do
      default_margin_pdf = described_class.build
      narrow_margin_pdf = described_class.build(margin: 0)

      expect(narrow_margin_pdf.bounds.width).to be > default_margin_pdf.bounds.width
    end
  end

  describe ".currency" do
    it "formats a value as Brazilian currency" do
      expect(described_class.currency(1234.5)).to eq("R$ 1.234,50")
    end
  end
end
