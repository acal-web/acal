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
        {
          connection_id: connection.id,
          customer: { id: connection.customer.id, name: connection.customer.name },
          address: { id: connection.address.id, name: connection.address.name },
          category: { id: connection.category.id, name: connection.category.name },
          membership_value: values[:membership_value],
          water_value: values[:water_value]
        }
      end
    end

    def self.value_breakdown(connection)
      {
        membership_value: connection.category.membership_price,
        water_value: connection.category.water_price
      }
    end
  end
end
