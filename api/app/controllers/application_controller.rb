class ApplicationController < ActionController::API
  include Paginatable

  before_action :authenticate_user!
  before_action :authorize_action!

  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid
  rescue_from ActiveRecord::RecordNotUnique, with: :render_duplicate
  rescue_from ApiError, with: :render_api_error

  private

  def current_session
    @current_session ||= Session.find_active_by_token(bearer_token)
  end

  def current_user
    @current_user ||= current_session&.user
  end

  def authenticate_user!
    raise UnauthenticatedError unless current_user
    current_session.touch_last_used!
  end

  def authorize_action!
    return if Permissions.allowed?(current_user, controller_name, action_name)
    raise ForbiddenError
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
