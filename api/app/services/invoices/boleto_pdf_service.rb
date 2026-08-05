module Invoices
  # Renders the printable invoice document for a single Invoice: two stacked
  # copies on one page (member's copy / association's copy), mirroring the
  # legacy rc_novaConta.jrxml / rc_exclusivo.jrxml layout.
  class BoletoPdfService
    COPY_LABELS = [ "Via do Sócio", "Via da Associação" ].freeze

    def self.call(invoice)
      new(invoice).call
    end

    def initialize(invoice)
      @invoice = invoice
      @connection = invoice.connection
    end

    def call
      pdf = PdfDocument.build

      COPY_LABELS.each_with_index do |label, index|
        pdf.move_down 24 if index.positive?
        draw_copy(pdf, label)
        pdf.move_down 12
        pdf.dash(4)
        pdf.stroke_horizontal_rule
        pdf.undash
      end

      pdf.render
    end

    private

    attr_reader :invoice, :connection

    def draw_copy(pdf, label)
      customer = connection.customer
      address = connection.address
      category = connection.category

      pdf.font(PdfDocument::FONT_NAME, style: :bold) { pdf.text "ACAL", size: 16 }
      pdf.text label, size: 9, color: "666666"
      pdf.move_down 10

      [
        [ "Sócio", customer.name ],
        [ "Nº de Sócio", customer.membership_number.to_s ],
        [ "Categoria", category.name ],
        [ "Ligação", "#{address.name}, #{connection.number}#{connection.letter}" ],
        [ "Referência", invoice.reference_date.strftime("%m/%Y") ],
        [ "Vencimento", invoice.due_date.strftime("%d/%m/%Y") ]
      ].each do |field, value|
        pdf.text "#{field}: #{value}", size: 10
      end

      pdf.move_down 10
      pdf.font(PdfDocument::FONT_NAME, style: :bold) do
        pdf.text "Valor Total: #{PdfDocument.currency(invoice.amount)}", size: 13
      end
    end
  end
end
