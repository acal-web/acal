module Notifications
  class RecipientsQuery
    def self.call(address_id: nil, category_id: nil, status: nil)
      connections = Connection
        .filter_by_address_id(address_id)
        .filter_by_category_id(category_id)
        .filter_by_status(status)

      Customer.where(id: connections.select(:customer_id)).distinct
    end
  end
end
