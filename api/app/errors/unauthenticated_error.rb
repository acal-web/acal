class UnauthenticatedError < ApiError
  CODE = 1002

  def initialize(message = "Authentication required")
    super(message, code: CODE, status: :unauthorized)
  end
end
