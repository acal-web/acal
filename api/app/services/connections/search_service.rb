module Connections
  class SearchService
    def self.call(filters = {})
      connection_scope = Connection
        .filter_by_customer_id(filters[:customer_id])
        .filter_by_customer_name(filters[:customer_name])
        .filter_by_customer_document(filters[:customer_document])
        .filter_by_address_name(filters[:address_name])
        .filter_by_category_id(filters[:category_id])

      if filters[:status].present?
        connection_scope = connection_scope.filter_by_status(filters[:status])
      elsif !filters[:active].nil?
        connection_scope = connection_scope.filter_by_active(filters[:active])
      end

      connection_scope
        .sort_by_field(filters[:sort_by], filters[:sort_direction])
        .includes(:customer, :address, :category)
    end
  end
end
