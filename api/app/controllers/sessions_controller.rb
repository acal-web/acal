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
      token = JwtToken.encode(user.id)
      render json: {
        token: token,
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
    # JWT is stateless, so there's nothing to destroy on the server
    # Client just discards the token
    head :no_content
  end
end
