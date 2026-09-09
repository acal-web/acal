module Reports
  # Cashbox report: paid invoices within a date range, plus the sum received.
  class CashboxReportBuilder
    def self.call(invoices, start_date:, end_date:)
      new(invoices, start_date:, end_date:).call
    end

    def initialize(invoices, start_date:, end_date:)
      @invoices = invoices
      @start_date = start_date
      @end_date = end_date
    end

    def call
      pdf = PdfFactory.build

      pdf.font(PdfFactory::FONT_NAME, style: :bold) { pdf.text "Relatório de Caixa", size: 16 }
      pdf.move_down 4
      pdf.text "Período: #{period_label}"
      pdf.move_down 16

      draw_invoices_table(pdf)

      pdf.move_down 12
      pdf.font(PdfFactory::FONT_NAME, style: :bold) do
        pdf.text "Valor Total Recebido: #{PdfFactory.currency(total_amount)}"
      end

      pdf.render
    end

    private

    attr_reader :invoices, :start_date, :end_date

    def period_label
      return "todos os registros" if start_date.blank? || end_date.blank?

      "#{Date.parse(start_date).strftime('%d/%m/%Y')} a #{Date.parse(end_date).strftime('%d/%m/%Y')}"
    end

    def total_amount
      invoices.sum(&:amount)
    end

    def draw_invoices_table(pdf)
      rows = invoices.map do |invoice|
        [
          invoice.paid_at.strftime("%d/%m/%Y"),
          invoice.number,
          invoice.connection.customer.name,
          PdfFactory.currency(invoice.amount)
        ]
      end

      pdf.table([ [ "Data Pagto.", "Fatura", "Sócio", "Valor" ] ] + rows, header: true, width: pdf.bounds.width) do |t|
        t.row(0).font_style = :bold
        t.cells.padding = 6
        t.column(3).align = :right
      end
    end
  end
end
