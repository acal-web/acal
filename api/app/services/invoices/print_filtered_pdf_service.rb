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

      @invoices.each_with_index do |invoice, index|
        pdf.start_new_page unless index.zero?
        BoletoPdfService.draw(pdf, invoice)
      end

      pdf.render
    end
  end
end
