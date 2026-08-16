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

      reference = reference_date.is_a?(Date) ? reference_date : Date.parse(reference_date.to_s)
      previous_month = reference.prev_month
      previous_meters_by_connection = load_previous_water_meters(connections, previous_month)

      connections.map do |connection|
        values = value_breakdown(connection)
        {
          connection_id: connection.id,
          customer: { id: connection.customer.id, name: connection.customer.name },
          address: { id: connection.address.id, name: connection.address.name },
          number: connection.number,
          letter: connection.letter,
          category: { id: connection.category.id, name: connection.category.name, has_water_meter: connection.category.has_water_meter },
          membership_value: values[:membership_value],
          water_value: values[:water_value],
          previous_meter_final_reading: previous_meters_by_connection[connection.id]
        }
      end
    end

    def self.value_breakdown(connection)
      {
        membership_value: connection.category.membership_price,
        water_value: connection.category.water_price
      }
    end

    def self.load_previous_water_meters(connections, previous_month)
      connection_ids = connections.map(&:id)
      previous_invoices = Invoice
        .where(connection_id: connection_ids, reference_date: previous_month.beginning_of_month..previous_month.end_of_month)
        .select(:id, :connection_id)
        .index_by(&:id)

      return {} if previous_invoices.empty?

      invoice_ids = previous_invoices.keys
      water_meters = WaterMeter.unscoped.where(invoice_id: invoice_ids).select(:invoice_id, :final_reading)

      water_meters.each_with_object({}) do |meter, memo|
        invoice = previous_invoices[meter.invoice_id]
        memo[invoice.connection_id] = meter.final_reading
      end
    end
  end
end
