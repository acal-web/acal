class NotificationSerializer
  include JSONAPI::Serializer

  attributes :title, :body, :recipient_count, :status, :created_at

  attribute :address_name do |notification|
    notification.address&.name
  end

  attribute :category_name do |notification|
    notification.category&.name
  end

  attribute :sent_by_name do |notification|
    notification.sent_by&.name
  end
end
