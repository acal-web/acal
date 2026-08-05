module Connections
  class CreateService
    def self.call(customer_id:, address_id:, category_id:, number:, letter: nil, active: true, legacy_id: nil, membership_date: nil, exclusively_member: false)
      Connection.create!(customer_id:, address_id:, category_id:, number:, letter:, active:, legacy_id:, membership_date:, exclusively_member:)
    end
  end
end
