module Reports
  # Business data for one connection's dunning letter: the group hash built
  # by Invoices::OverdueConnectionsService, shaped into presentation-ready
  # values. Reports::DunningReportBuilder only lays these out.
  class DunningReport
    def initialize(group)
      @group = group
    end

    def customer_name
      group[:customer][:name]
    end

    def connection_location
      "#{group[:address][:name]}, nº #{group[:connection_number]}"
    end

    def invoice_rows
      group[:invoices].map do |invoice|
        [
          invoice[:reference_date].strftime("%m/%Y"),
          invoice[:due_date].strftime("%d/%m/%Y"),
          PdfFactory.currency(invoice[:membership_value] + invoice[:water_value])
        ]
      end
    end

    def total_label
      PdfFactory.currency(group[:total_amount])
    end

    private

    attr_reader :group
  end
end
