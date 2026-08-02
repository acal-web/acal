module Connections
  class CreateService
    def self.call(customer_id:, address_id:, category_id:, active: true, legacy_id: nil)
      Connection.create!(customer_id:, address_id:, category_id:, active:, legacy_id:)
    end
  end
end
