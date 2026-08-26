class Portal::ApplicationController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :authorize_action!
  before_action :authenticate_customer!

  private

  def current_customer
    @current_customer ||= begin
      payload = JwtToken.decode(bearer_token)
      return nil unless payload

      Customer.find_by(id: payload[:customer_id])
    end
  end

  def authenticate_customer!
    raise UnauthenticatedError unless current_customer
  end
end
