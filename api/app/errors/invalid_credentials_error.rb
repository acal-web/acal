class InvalidCredentialsError < ApiError
  CODE = 1004

  def initialize(message = "Invalid username or password")
    super(message, code: CODE, status: :unauthorized)
  end
end
