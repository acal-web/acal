module Invoices
  # Renders a dunning letter per connection group (as produced by
  # OverdueConnectionsService), one per page, listing its open overdue
  # invoices and the total owed — mirrors the legacy rc_cobranca.jrxml /
  # rc_cobranca_detalhe.jrxml pair.
  class CobrancaPdfService
    def self.call(groups)
      new(groups).call
    end

    def initialize(groups)
      @groups = groups
    end

    def call
      pdf = PdfDocument.build

      groups.each_with_index do |group, index|
        pdf.start_new_page if index.positive?
        draw_letter(pdf, group)
      end

      pdf.render
    end

    private

    attr_reader :groups

    def draw_letter(pdf, group)
      pdf.font(PdfDocument::FONT_NAME, style: :bold) { pdf.text "ACAL", size: 16 }
      pdf.move_down 16
      pdf.text Date.current.strftime("%d/%m/%Y"), align: :right
      pdf.move_down 16

      pdf.text "Prezado(a) sócio(a) #{group[:customer][:name]},"
      pdf.move_down 8
      pdf.text "Segundo nosso cadastro, os débitos abaixo referentes à ligação em " \
                "#{group[:address][:name]}, nº #{group[:connection_number]}, constam como em aberto:"
      pdf.move_down 12

      draw_invoices_table(pdf, group[:invoices])

      pdf.move_down 12
      pdf.font(PdfDocument::FONT_NAME, style: :bold) do
        pdf.text "Valor Total em Aberto: #{PdfDocument.currency(group[:total_amount])}"
      end

      pdf.move_down 24
      pdf.text "Pedimos a gentileza de regularizar o pagamento o quanto antes."
    end

    def draw_invoices_table(pdf, invoices)
      rows = [ [ "Referência", "Vencimento", "Valor" ] ]
      rows += invoices.map { |invoice|
        [
          invoice[:reference_date].strftime("%m/%Y"),
          invoice[:due_date].strftime("%d/%m/%Y"),
          PdfDocument.currency(invoice[:amount])
        ]
      }

      pdf.table(rows, header: true, width: pdf.bounds.width) do |t|
        t.row(0).font_style = :bold
        t.cells.padding = 6
      end
    end
  end
end
