class ApplicationController < ActionController::API
  include Paginatable

  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid
  rescue_from ApiError, with: :render_api_error

  private

  def render_invalid(exception)
    render json: exception.record.errors, status: :unprocessable_content
  end

  def render_api_error(exception)
    render json: { code: exception.code, message: exception.message }, status: :unprocessable_content
  end
end
