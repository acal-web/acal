module Invoices
  # Renders the same boleto layout as Invoices::BoletoPdfService, one per
  # page, for every invoice in the filtered set — so "Imprimir Filtrados"
  # produces the exact report a user gets from "Imprimir Boleto" on a
  # single row, just concatenated.
  class PrintFilteredPdfService
    def self.call(invoices)
      new(invoices).call
    end

    def initialize(invoices)
      @invoices = invoices
    end

    def call
      pdf = PdfDocument.build(margin: 22)
      analyses_by_month = preload_quality_analyses

      @invoices.each_with_index do |invoice, index|
        pdf.start_new_page unless index.zero?
        key = [ invoice.reference_date.year, invoice.reference_date.month ]
        BoletoPdfService.draw(pdf, invoice, quality_analyses: analyses_by_month[key] || [])
      end

      pdf.render
    end

    private

    # One query for the whole batch's date span instead of one per invoice —
    # invoices printed together typically share (or cluster around) the same
    # reference month, so grouping in Ruby avoids re-fetching identical rows.
    def preload_quality_analyses
      dates = @invoices.map(&:reference_date).compact
      return {} if dates.empty?

      QualityAnalysis
        .where(reference_date: dates.min.beginning_of_month..dates.max.end_of_month)
        .group_by { |qa| [ qa.reference_date.year, qa.reference_date.month ] }
    end
  end
end
