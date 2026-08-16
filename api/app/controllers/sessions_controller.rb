class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: :create
  skip_before_action :authorize_action!

  # POST /session
  def create
    user = User.find_by(username: params.dig(:session, :username).to_s.strip.downcase)
    if user&.authenticate(params.dig(:session, :password).to_s)
      session, raw_token = Session.start_for!(user, user_agent: request.user_agent, ip_address: request.remote_ip)
      render json: { token: raw_token, user: UserSerializer.new(user) }, status: :created
    else
      raise InvalidCredentialsError
    end
  end

  # DELETE /session
  def destroy
    current_session&.destroy
    head :no_content
  end
end
