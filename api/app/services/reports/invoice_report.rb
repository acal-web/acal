module Reports
  class InvoiceReport
    MONTH_NAMES = %w[janeiro fevereiro março abril maio junho julho agosto setembro outubro novembro dezembro].freeze
    MONTH_ABBR = %w[jan fev mar abr mai jun jul ago set out nov dez].freeze

    LEGEND = [
      [ "Coliformes Totais", "Indicador que mensura contaminação bacteriológica, do tipo: bacilos gram-negativos, aeróbios ou anaeróbios facultativos não esporogênicos, oxidase-negativos." ],
      [ "E.coli", "Indicador que mensura contaminação bacteriológica de origem fecal." ],
      [ "Cloro Residual", "Indicador de Poder Desinfetante oriundo do Cloro (Agente de Desinfecção)." ],
      [ "Turbidez", "Indicador do espalhamento de luz produzido pela presença de partículas em suspensão ou coloidais." ],
      [ "Cor Aparente", "Indicador que mensura a cor em amostras com turbidez." ]
    ].freeze

    def initialize(invoice, quality_analyses: nil)
      @invoice = invoice
      @connection = invoice.connection
      @quality_analyses = quality_analyses
    end

    def associate_number
      connection.legacy_id&.to_s || "—"
    end

    def customer_name
      connection.customer.name
    end

    def address
      connection.full_location
    end

    def category_name
      connection.category.name
    end

    def meter
      invoice.water_meter
    end

    def meter_readings
      return [ "—", "—", "—" ] unless meter

      [
        "#{number_with_thousands(meter.initial_reading.to_i)} L",
        "#{number_with_thousands(meter.final_reading.to_i)} L",
        "#{number_with_thousands(meter.real_consumption.to_i)} L"
      ]
    end

    def boleto_number
      invoice.number || "—"
    end

    def paid?
      invoice.paid_at.present?
    end

    def paid_at_label
      short_date(invoice.paid_at.to_date) if paid?
    end

    def reference_label
      month_year_label(invoice.reference_date)
    end

    def issued_at_label
      short_date(invoice.reference_date)
    end

    def due_date_label
      short_date(invoice.due_date)
    end

    def membership_value_label
      PdfFactory.currency(invoice.membership_value)
    end

    def water_value_label
      PdfFactory.currency(invoice.water_value)
    end

    def excess_water_value_label
      PdfFactory.currency(invoice.water_consumed_value || 0)
    end

    def total_value_label
      PdfFactory.currency(invoice.amount)
    end

    def quality_analyses
      @quality_analyses || invoice.quality_analyses.to_a
    end

    private

    attr_reader :invoice, :connection

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
