module Reports
  class FilteredInvoicesReportBuilder
    def self.call(invoices)
      new(invoices).call
    end

    def initialize(invoices)
      @invoices = invoices
    end

    def call
      pdf = PdfFactory.build(margin: 22)
      analyses_by_month = preload_quality_analyses

      @invoices.each_with_index do |invoice, index|
        pdf.start_new_page unless index.zero?
        key = [ invoice.reference_date.year, invoice.reference_date.month ]
        InvoiceReportBuilder.draw(pdf, invoice, quality_analyses: analyses_by_month[key] || [])
      end

      pdf.render
    end

    private

    def preload_quality_analyses
      dates = @invoices.map(&:reference_date).compact
      return {} if dates.empty?

      QualityAnalysis
        .where(reference_date: dates.min.beginning_of_month..dates.max.end_of_month)
        .group_by { |qa| [ qa.reference_date.year, qa.reference_date.month ] }
    end
  end
end
