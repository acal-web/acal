class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: :create
  skip_before_action :authorize_action!

  # POST /session
  def create
    username = params.dig(:session, :username).to_s.strip.downcase
    password = params.dig(:session, :password).to_s

    raise InvalidCredentialsError if username.blank? || password.blank?

    user = User.find_by(username: username)
    if user&.authenticate(password)
      session, raw_token = Session.start_for!(user, user_agent: request.user_agent, ip_address: request.remote_ip)
      render json: {
        token: raw_token,
        user: {
          id: user.id,
          username: user.username,
          name: user.name,
          role: user.role,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      }, status: :created
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
