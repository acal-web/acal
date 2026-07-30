class ApplicationController < ActionController::API
  include Paginatable

  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid

  private

  def render_invalid(exception)
    render json: exception.record.errors, status: :unprocessable_content
  end
end
