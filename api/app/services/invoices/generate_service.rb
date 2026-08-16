module Invoices
  class GenerateService
    def self.call(connection_ids:, reference_date:, due_date:, water_meters: nil)
      connections = Connection.where(id: connection_ids).includes(:category)
      water_meters_by_connection = (water_meters || {}).index_by { |m| m["connection_id"] }

      ActiveRecord::Base.transaction do
        connections.map do |connection|
          values = EligibleConnectionsService.value_breakdown(connection)
          invoice = Invoice.create!(
            connection_id: connection.id,
            reference_date: reference_date,
            due_date: due_date,
            membership_value: values[:membership_value],
            water_value: values[:water_value]
          )

          meter_data = water_meters_by_connection[connection.id]
          if meter_data&.dig("initial_reading").present? && meter_data&.dig("final_reading").present?
            WaterMeter.create!(
              invoice_id: invoice.id,
              measured_at: reference_date,
              initial_reading: meter_data["initial_reading"],
              final_reading: meter_data["final_reading"]
            )
          end

          invoice
        end
      end
    end
  end
end
