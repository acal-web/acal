class ApplicationController < ActionController::API
  include Paginatable
  include Permittable

  before_action :authenticate_token!
  before_action :authorize_action!

  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid
  rescue_from ActiveRecord::RecordNotUnique, with: :render_duplicate
  rescue_from ApiError, with: :render_api_error

  private

  def token_payload
    @token_payload ||= JwtToken.decode(bearer_token)
  end

  def current_group
    token_payload && token_payload[:group]
  end

  def current_user
    @current_user ||= token_payload&.dig(:user_id) && User.find_by(id: token_payload[:user_id])
  end

  def authenticate_token!
    return if required_permission == :public

    raise UnauthenticatedError unless token_payload && current_group
  end

  def authorize_action!
    return if required_permission == :public

    raise ForbiddenError unless Rbac.can?(current_group, required_permission)
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    header.start_with?("Bearer ") ? header.delete_prefix("Bearer ") : nil
  end

  def render_invalid(exception)
    render json: exception.record.errors, status: :unprocessable_content
  end

  def render_duplicate(_exception)
    render_api_error(DuplicateResourceError.new("#{controller_name.classify} already exists"))
  end

  def render_api_error(exception)
    render json: { code: exception.code, message: exception.message }, status: exception.status
  end
end
