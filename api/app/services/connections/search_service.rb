module Connections
  class SearchService
    def self.call(customer_id: nil, customer_name: nil, customer_document: nil, address_name: nil, category_id: nil, active: nil, status: nil, sort_by: nil, sort_direction: nil)
      connection_scope = Connection
        .filter_by_customer_id(customer_id)
        .filter_by_customer_name(customer_name)
        .filter_by_customer_document(customer_document)
        .filter_by_address_name(address_name)
        .filter_by_category_id(category_id)

      if status.present?
        connection_scope = connection_scope.filter_by_status(status)
      elsif active.present?
        connection_scope = connection_scope.filter_by_active(active)
      end

      connection_scope
        .sort_by_field(sort_by, sort_direction)
        .includes(:customer, :address, :category)
    end
  end
end
