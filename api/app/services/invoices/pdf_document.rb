module Invoices
  # Shared Prawn::Document factory for invoice-related PDFs. Registers a
  # UTF-8 TrueType font since Prawn's built-in AFM fonts (Helvetica) can't
  # render the accented Portuguese text used throughout these documents.
  module PdfDocument
    FONT_DIR = Rails.root.join("app/assets/fonts")
    FONT_NAME = "DejaVuSans"

    def self.build(**options)
      pdf = Prawn::Document.new(**{ page_size: "A4", margin: 36 }.merge(options))
      pdf.font_families.update(
        FONT_NAME => {
          normal: FONT_DIR.join("DejaVuSans.ttf").to_s,
          bold: FONT_DIR.join("DejaVuSans-Bold.ttf").to_s
        }
      )
      pdf.font(FONT_NAME)
      pdf
    end

    def self.currency(value)
      ActiveSupport::NumberHelper.number_to_currency(value, unit: "R$ ", separator: ",", delimiter: ".")
    end
  end
end
