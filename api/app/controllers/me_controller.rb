class MeController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authorize_action!

  # GET /me
  def show
    render json: {
      id: current_user.id,
      username: current_user.username,
      name: current_user.name,
      role: current_user.role,
      created_at: current_user.created_at,
      updated_at: current_user.updated_at
    }
  end
end
