class MeController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authorize_action!

  # GET /me
  def show
    render json: UserSerializer.new(current_user)
  end
end
