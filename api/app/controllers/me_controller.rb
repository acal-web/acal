class MeController < ApplicationController
  allow_any_group only: :show

  # GET /me
  def show
    render json: UserPayload.build(current_user)
  end
end
