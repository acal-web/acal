module Invoices
  # Generates a PDF report with all filtered invoices
  class PrintFilteredPdfService
    def self.call(invoices)
      new(invoices).call
    end

    def initialize(invoices)
      @invoices = invoices
    end

    def call
      pdf = PdfDocument.build

      pdf.text "Relatório de Faturas", size: 16, style: :bold
      pdf.text "Data: #{Date.current.strftime('%d/%m/%Y')}", size: 10, color: "666666"
      pdf.move_down 12

      draw_table(pdf)

      pdf.render
    end

    private

    def draw_table(pdf)
      data = [
        [ "Número", "Referência", "Sócio", "Ligação", "Vencimento", "Valor", "Status" ],
        *@invoices.map { |invoice| format_row(invoice) }
      ]

      pdf.table(data, header: true, width: pdf.bounds.width) do |table|
        table.row(0).font_style = :bold
        table.row(0).background_color = "CCCCCC"
        table.columns(0..6).align = :left
        table.columns(5).align = :right
        table.columns(6).align = :center
      end

      pdf.move_down 12
      pdf.text "Total de faturas: #{@invoices.count}", size: 10, color: "666666"
      total_amount = @invoices.sum { |i| i.membership_value + i.water_value }
      pdf.text "Total: R$ #{format('%.2f', total_amount).gsub('.', ',')}", size: 10, style: :bold
    end

    def format_row(invoice)
      customer_name = invoice.connection&.customer&.name || "-"
      address_name = invoice.connection&.address&.name || "-"
      connection_number = invoice.connection&.number || "-"
      letter = invoice.connection&.letter.presence || ""

      reference = "#{invoice.reference_date.month.to_s.rjust(2, '0')}/#{invoice.reference_date.year}"
      due_date = invoice.due_date.strftime("%d/%m/%Y")
      amount = "R$ #{format('%.2f', invoice.membership_value + invoice.water_value).gsub('.', ',')}"
      status = invoice.paid_at.present? ? "Paga" : "Aberto"

      [
        invoice.number,
        reference,
        customer_name[0..20],
        "#{address_name[0..15]}, #{connection_number}#{letter}",
        due_date,
        amount,
        status
      ]
    end
  end
end
