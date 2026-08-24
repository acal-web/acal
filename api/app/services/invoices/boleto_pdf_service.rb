module Invoices
  # Renders a single A4 page with two stacked copies ("Nº de Associado" block
  # onward, separated by a dashed rule) under one shared letterhead — mirrors
  # the legacy printed layout while using the current field set (membership/
  # water/excess values) from the Flutter invoice detail card.
  class BoletoPdfService
    MONTH_NAMES = %w[janeiro fevereiro março abril maio junho julho agosto setembro outubro novembro dezembro].freeze
    MONTH_ABBR = %w[jan fev mar abr mai jun jul ago set out nov dez].freeze

    LEGEND = [
      [ "Coliformes Totais", "Indicador que mensura contaminação bacteriológica, do tipo: bacilos gram-negativos, aeróbios ou anaeróbios facultativos não esporogênicos, oxidase-negativos." ],
      [ "E.coli", "Indicador que mensura contaminação bacteriológica de origem fecal." ],
      [ "Cloro Residual", "Indicador de Poder Desinfetante oriundo do Cloro (Agente de Desinfecção)." ],
      [ "Turbidez", "Indicador do espalhamento de luz produzido pela presença de partículas em suspensão ou coloidais." ],
      [ "Cor Aparente", "Indicador que mensura a cor em amostras com turbidez." ]
    ].freeze

    BORDER_COLOR = "999999"
    BOX_HEIGHT = 56
    GAP = 8

    def self.call(invoice)
      pdf = PdfDocument.build(margin: 22)
      new(invoice).draw(pdf)
      pdf.render
    end

    # Draws one invoice's boleto onto an existing document, so callers that
    # print multiple invoices (e.g. Invoices::PrintFilteredPdfService) can
    # reuse this exact layout instead of maintaining a second template.
    #
    # quality_analyses: lets batch callers pass in a preloaded set (shared
    # across every invoice from the same reference month) instead of each
    # invoice re-querying for it individually.
    def self.draw(pdf, invoice, quality_analyses: nil)
      new(invoice, quality_analyses: quality_analyses).draw(pdf)
    end

    def initialize(invoice, quality_analyses: nil)
      @invoice = invoice
      @connection = invoice.connection
      @quality_analyses = quality_analyses
    end

    def draw(pdf)
      draw_letterhead(pdf)

      # The water quality summary is shared account-wide for the reference
      # month, so it's only printed once — not duplicated per copy.
      draw_columns(pdf)
      pdf.move_down 6
      draw_water_quality(pdf)

      draw_divider(pdf)

      draw_columns(pdf)
    end

    private

    attr_reader :invoice, :connection

    def draw_divider(pdf)
      pdf.move_down 6
      pdf.stroke_color BORDER_COLOR
      pdf.dash(3)
      pdf.stroke_horizontal_rule
      pdf.undash
      pdf.stroke_color "000000"
      pdf.move_down 6
    end

    # -- Letterhead (once per page) -----------------------------------------

    def draw_letterhead(pdf)
      icon_size = 34
      text_x = icon_size + 16
      top = pdf.cursor

      pdf.bounding_box([ text_x, top ], width: pdf.bounds.width - text_x) do
        pdf.text [
          "CNPJ - 13.228.119/0001-68",
          "Publicação do estatuto no Diário Oficial de 22-06-1983",
          "Reconhecido como Órgão de utilidade pública Municipal - conf.lei N 7 de 27-10-1983",
          "Reconhecido como Órgão de utilidade pública Estadual - conf.lei N 7049 de 16-04-1997",
          "Rua Morro do Chapéu, S/N - Tel 0(xx74) 3674-2165 - Lages do Batata - Jacobina BA",
          "Email: acalages@hotmail.com"
        ].join("\n"), size: 7, color: "666666", leading: 0
      end

      draw_building_icon(pdf, 0, top, pdf.cursor, icon_size)
      pdf.move_down 6

      pdf.stroke_color BORDER_COLOR
      pdf.stroke_horizontal_rule
      pdf.stroke_color "000000"
      pdf.move_down 8

      pdf.formatted_text [ { text: "ACAL - Associação Comunitária e Assistencial de Lages", styles: [ :bold, :underline ], size: 15 } ], align: :center
      pdf.formatted_text [ { text: "ECONOMIZAR ÁGUA É UM DEVER DE TODO SER HUMANO.", styles: [ :bold, :underline ], size: 10 } ], align: :center
      pdf.move_down 8

      pdf.stroke_color BORDER_COLOR
      pdf.stroke_horizontal_rule
      pdf.stroke_color "000000"
      pdf.move_down 8
    end

    # Simple building glyph (outline + a grid of "window" squares) standing
    # in for the app's Icons.business, since no icon/logo asset is bundled.
    def draw_building_icon(pdf, x, top, bottom, target_size)
      size = [ target_size, top - bottom ].min
      y0 = (top + bottom) / 2.0 + size / 2.0

      pdf.fill_color "000000"
      pdf.rectangle([ x, y0 ], size, size)
      pdf.fill

      pad = size * 0.16
      cell = (size - pad * 3) / 2.0
      pdf.fill_color "FFFFFF"
      3.times do |row|
        2.times do |col|
          wx = x + pad + col * (cell + pad)
          wy = y0 - pad - row * (cell + pad)
          pdf.rectangle([ wx, wy ], cell, cell)
          pdf.fill
        end
      end
      pdf.fill_color "000000"
    end

    # -- 3 full columns: Identity (+meter) | Boleto/Pago | Datas/Valores/Total
    # Mirrors InvoiceCustomerSection / InvoicePaymentSection / InvoiceSummarySection.

    COLUMN_HEIGHT = 210

    def draw_columns(pdf)
      width = pdf.bounds.width
      col_width = (width - GAP * 2) / 3.0
      top = pdf.cursor

      pdf.float { pdf.bounding_box([ 0, top ], width: col_width, height: COLUMN_HEIGHT) { draw_identity_column(pdf, col_width) } }
      pdf.float { pdf.bounding_box([ col_width + GAP, top ], width: col_width, height: COLUMN_HEIGHT) { draw_payment_column(pdf, col_width) } }
      pdf.float { pdf.bounding_box([ (col_width + GAP) * 2, top ], width: col_width, height: COLUMN_HEIGHT) { draw_values_column(pdf, col_width) } }

      pdf.move_down COLUMN_HEIGHT
    end

    def draw_box(pdf, width, height, label, value, value_size: 14)
      y = pdf.cursor

      pdf.stroke_color BORDER_COLOR
      pdf.rounded_rectangle([ 0, y ], width, height, 6)
      pdf.stroke
      pdf.stroke_color "000000"

      content_height = 9 + 3 + value_size
      top_pad = [ (height - content_height) / 2.0, 4 ].max

      pdf.move_down top_pad
      pdf.text label, size: 9, style: :bold, color: "666666", align: :center
      pdf.move_down 3
      pdf.font(PdfDocument::FONT_NAME, style: :bold) { pdf.text value, size: value_size, align: :center }

      pdf.move_down(height - top_pad - content_height)
    end

    def draw_identity_column(pdf, width)
      customer = connection.customer
      category = connection.category

      draw_box(pdf, width, BOX_HEIGHT, "Nº de Associado", connection.legacy_id&.to_s || "—", value_size: 14)
      pdf.move_down GAP

      draw_rows(pdf, [
        [ "Sócio", customer.name ],
        [ "Endereço", connection.full_location ],
        [ "Categoria", category.name ]
      ], width)

      pdf.move_down 6
      draw_meter_box(pdf, width, pdf.cursor)
    end

    def draw_meter_box(pdf, width, height)
      return if height < 20

      meter = invoice.water_meter
      y = pdf.cursor

      pdf.stroke_color BORDER_COLOR
      pdf.rectangle([ 0, y ], width, height)
      pdf.stroke
      pdf.stroke_color "000000"

      col_width = width / 3.0

      [
        [ "Leitura anterior:", meter ? "#{number_with_thousands(meter.initial_reading.to_i)} L" : "—" ],
        [ "Leitura atual:", meter ? "#{number_with_thousands(meter.final_reading.to_i)} L" : "—" ],
        [ "Consumo:", meter ? "#{number_with_thousands(meter.real_consumption.to_i)} L" : "—" ]
      ].each_with_index do |(label, value), index|
        x = index * col_width

        pdf.text_box label, at: [ x + 5, y - 8 ], width: col_width - 8, height: 16,
                             size: 7, style: :bold, color: "666666", overflow: :shrink_to_fit
        pdf.text_box value, at: [ x + 5, y - 24 ], width: col_width - 8, height: 16,
                             size: 11, style: :bold, overflow: :shrink_to_fit
      end
    end

    def draw_payment_column(pdf, width)
      draw_box(pdf, width, BOX_HEIGHT, "Boleto nº", invoice.number || "—", value_size: 14)
      pdf.move_down GAP

      height = pdf.cursor
      return if height < 4

      y = pdf.cursor
      pdf.stroke_color BORDER_COLOR
      pdf.rectangle([ 0, y ], width, height)
      pdf.stroke
      pdf.stroke_color "000000"

      # Left blank when the invoice hasn't been paid yet — mirrors the app,
      # which renders an empty box in that case instead of a placeholder.
      return unless invoice.paid_at.present?

      pdf.text_box "Pago em", at: [ 0, y - 14 ], width: width, height: 12, size: 9, color: "666666", align: :center
      pdf.text_box short_date(invoice.paid_at.to_date), at: [ 0, y - 30 ], width: width, height: 18, size: 13, style: :bold, align: :center
    end

    def draw_values_column(pdf, width)
      draw_box(pdf, width, BOX_HEIGHT, "Conta referente", month_year_label(invoice.reference_date), value_size: 13)
      pdf.move_down GAP

      draw_rows(pdf, [
        [ "Data de Emissão", short_date(invoice.reference_date) ],
        [ "Vencimento", short_date(invoice.due_date) ]
      ], width, value_align: :right)

      pdf.move_down 4

      draw_rows(pdf, [
        [ "Valor Societario", PdfDocument.currency(invoice.membership_value) ],
        [ "Valor Água", PdfDocument.currency(invoice.water_value) ],
        [ "Água excedente", PdfDocument.currency(invoice.water_consumed_value || 0) ]
      ], width, value_align: :right)

      pdf.move_down 8
      draw_total_box(pdf, width, 32, "Valor total", PdfDocument.currency(invoice.amount))
    end

    def draw_total_box(pdf, width, height, label, value)
      y = pdf.cursor

      pdf.stroke_color BORDER_COLOR
      pdf.rounded_rectangle([ 0, y ], width, height, 6)
      pdf.stroke
      pdf.stroke_color "000000"

      content_height = 14
      top_pad = [ (height - content_height) / 2.0, 4 ].max

      pdf.bounding_box([ 0, y ], width: width, height: height) do
        pdf.move_down top_pad
        pdf.table([ [ label, value ] ], column_widths: [ width * 0.5, width * 0.5 ],
                  cell_style: { borders: [], padding: [ 0, 4, 0, 4 ], size: 12, font_style: :bold }) do
          column(1).align = :right
        end
      end

      pdf.move_down height
    end

    # Label/value rows — label left, value either immediately after (identity
    # fields, where lengths vary too much to right-align) or right-aligned
    # (dates/money, mirroring the app's summary rows).
    def draw_rows(pdf, rows, width, value_align: :left)
      pdf.table(rows, column_widths: [ width * 0.42, width * 0.58 ],
                cell_style: { borders: [], padding: [ 1, 0, 1, 0 ], size: 9 }) do
        column(0).font_style = :bold if value_align == :left
        column(1).align = value_align
      end
    end

    # -- Water quality table + legend ---------------------------------------

    def draw_water_quality(pdf)
      analyses = @quality_analyses || invoice.quality_analyses.to_a

      pdf.font(PdfDocument::FONT_NAME, style: :bold) { pdf.text "PADRÃO DA PORTARIA MS 2914/2011", size: 10, align: :center }
      pdf.move_down 4

      if analyses.empty?
        y = pdf.cursor
        pdf.stroke_color BORDER_COLOR
        pdf.rectangle([ 0, y ], pdf.bounds.width, 18)
        pdf.stroke
        pdf.stroke_color "000000"
        pdf.bounding_box([ 0, y ], width: pdf.bounds.width, height: 18) do
          pdf.move_down 4
          pdf.text "Sem dados de análise de qualidade disponíveis", size: 8, color: "999999", align: :center
        end
        pdf.move_down 18 + 6
      else
        rows = [ [ { content: "Decreto Federal nº 5.440/2005", colspan: 4 } ] ]
        rows += [ [ "Parâmetros", "Exigidas", "Analisadas", "Em Conformidade" ] ]
        rows += analyses.map { |a| [ a.param_name, a.required.to_s, a.analyzed.to_s, a.compliant.to_s ] }

        pdf.table(rows, width: pdf.bounds.width, cell_style: { size: 8, align: :center, padding: [ 3, 4, 3, 4 ] }) do
          row(0).font_style = :bold
          row(0).background_color = "EEEEEE"
          row(1).font_style = :bold
          column(0).align = :left
          row(0).align = :center
        end
        pdf.move_down 6
      end

      draw_legend(pdf)
    end

    def draw_legend(pdf)
      pdf.font(PdfDocument::FONT_NAME, style: :bold) { pdf.text "Parâmetros de Qualidade da Água", size: 9 }
      pdf.move_down 3

      LEGEND.each do |title, description|
        pdf.formatted_text [
          { text: "#{title}: ", styles: [ :bold ], size: 7 },
          { text: description, size: 7 }
        ], leading: 0
      end
    end

    def month_year_label(date)
      "#{MONTH_NAMES[date.month - 1]}, #{date.year}"
    end

    def short_date(date)
      "#{date.strftime('%d')} #{MONTH_ABBR[date.month - 1]}. #{date.year}"
    end

    def number_with_thousands(value)
      ActiveSupport::NumberHelper.number_to_delimited(value, delimiter: ".")
    end
  end
end
