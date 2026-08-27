module Reports
  class DunningReportBuilder
    def self.call(groups)
      new(groups).call
    end

    def initialize(groups)
      @groups = groups
    end

    def call
      pdf = PdfFactory.build

      groups.each_with_index do |group, index|
        pdf.start_new_page if index.positive?
        draw_letter(pdf, DunningReport.new(group))
      end

      pdf.render
    end

    private

    attr_reader :groups

    def draw_letter(pdf, report)
      pdf.font(PdfFactory::FONT_NAME, style: :bold) { pdf.text "ACAL", size: 16 }
      pdf.move_down 16
      pdf.text Date.current.strftime("%d/%m/%Y"), align: :right
      pdf.move_down 16

      pdf.text "Prezado(a) sócio(a) #{report.customer_name},"
      pdf.move_down 8
      pdf.text "Segundo nosso cadastro, os débitos abaixo referentes à ligação em " \
                "#{report.connection_location}, constam como em aberto:"
      pdf.move_down 12

      draw_invoices_table(pdf, report.invoice_rows)

      pdf.move_down 12
      pdf.font(PdfFactory::FONT_NAME, style: :bold) do
        pdf.text "Valor Total em Aberto: #{report.total_label}"
      end

      pdf.move_down 24
      pdf.text "Pedimos a gentileza de regularizar o pagamento o quanto antes."
    end

    def draw_invoices_table(pdf, rows)
      pdf.table([ [ "Referência", "Vencimento", "Valor" ] ] + rows, header: true, width: pdf.bounds.width) do |t|
        t.row(0).font_style = :bold
        t.cells.padding = 6
      end
    end
  end
end
