module Connections
  class SearchService
    def self.call(customer_name: nil, customer_document: nil, address_name: nil, category_id: nil, active: nil)
      Connection
        .filter_by_customer_name(customer_name)
        .filter_by_customer_document(customer_document)
        .filter_by_address_name(address_name)
        .filter_by_category_id(category_id)
        .filter_by_active(active)
        .includes(:customer, :address, :category)
    end
  end
end
