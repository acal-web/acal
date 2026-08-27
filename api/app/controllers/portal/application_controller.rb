class Portal::ApplicationController < ApplicationController
  private

  def current_customer
    @current_customer ||= token_payload&.dig(:customer_id) && Customer.find_by(id: token_payload[:customer_id])
  end

  def authenticate_token!
    super

    raise UnauthenticatedError unless required_permission == :public || token_payload&.dig(:customer_id)
  end
end
