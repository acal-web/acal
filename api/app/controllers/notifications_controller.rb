class NotificationsController < ApplicationController
  requires_permission "notifications:read", only: %i[ index recipients_count ]
  requires_permission "notifications:send", only: :create

  # GET /notifications
  def index
    notifications = Notification.order(created_at: :desc)
    render json: paginate(notifications), each_serializer: NotificationSerializer
  end

  # GET /notifications/recipients_count
  def recipients_count
    count = Notifications::RecipientsQuery.call(
      address_id: params[:address_id], category_id: params[:category_id], status: params[:status]
    ).count

    render json: { count: }
  end

  # POST /notifications
  def create
    address_id = notification_params[:address_id]
    category_id = notification_params[:category_id]
    status = notification_params[:status]

    customers = Notifications::RecipientsQuery.call(address_id:, category_id:, status:)

    notification = Notification.create!(
      title: notification_params[:title],
      body: notification_params[:body],
      address_id:, category_id:, status:,
      recipient_count: customers.count,
      sent_by: current_user
    )

    Notifications::BroadcastJob.perform_later(notification.id)

    render json: notification, status: :created
  end

  private

  def notification_params
    params.expect(notification: [ :title, :body, :address_id, :category_id, :status ])
  end
end
