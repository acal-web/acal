module Invoices
  class EligibleConnectionsService
    def self.call(reference_date:, has_water_meter: nil, address_id: nil)
      already_invoiced = Invoice.where(reference_date: reference_date).select(:connection_id)

      connections = Connection
        .filter_by_active(true)
        .filter_by_has_water_meter(has_water_meter)
        .filter_by_address_id(address_id)
        .where.not(id: already_invoiced)
        .includes(:customer, :address, :category)

      connections.map do |connection|
        values = value_breakdown(connection)
        previous_water_meter = previous_water_meter_for(connection, reference_date)
        {
          connection_id: connection.id,
          customer: { id: connection.customer.id, name: connection.customer.name },
          address: { id: connection.address.id, name: connection.address.name },
          number: connection.number,
          letter: connection.letter,
          category: { id: connection.category.id, name: connection.category.name, has_water_meter: connection.category.has_water_meter },
          membership_value: values[:membership_value],
          water_value: values[:water_value],
          previous_meter_final_reading: previous_water_meter&.final_reading
        }
      end
    end

    def self.value_breakdown(connection)
      {
        membership_value: connection.category.membership_price,
        water_value: connection.category.water_price
      }
    end

    def self.previous_water_meter_for(connection, reference_date)
      reference = reference_date.is_a?(Date) ? reference_date : Date.parse(reference_date.to_s)
      previous_month = reference.prev_month
      previous_invoice = Invoice
        .where(connection_id: connection.id, reference_date: previous_month.beginning_of_month..previous_month.end_of_month)
        .first

      return nil unless previous_invoice

      WaterMeter.unscoped.find_by(invoice_id: previous_invoice.id)
    end
  end
end
