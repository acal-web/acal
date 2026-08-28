module Notifications
  class BroadcastService
    def self.call(title:, body:, customers:)
      customers.find_each do |customer|
        Devices::SendPushService.call(owner: customer, title:, body:)
      end
    end
  end
end
