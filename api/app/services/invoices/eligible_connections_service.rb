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
        {
          connection_id: connection.id,
          customer: { id: connection.customer.id, name: connection.customer.name },
          address: { id: connection.address.id, name: connection.address.name },
          category: { id: connection.category.id, name: connection.category.name },
          amount: amount_for(connection)
        }
      end
    end

    def self.amount_for(connection)
      connection.category.membership_price + connection.category.water_price
    end
  end
end
