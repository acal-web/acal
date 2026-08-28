module Notifications
  class BroadcastJob < ApplicationJob
    def perform(notification_id)
      notification = Notification.find(notification_id)
      customers = Notifications::RecipientsQuery.call(
        address_id: notification.address_id,
        category_id: notification.category_id,
        status: notification.status
      )

      Notifications::BroadcastService.call(title: notification.title, body: notification.body, customers:)
    end
  end
end
