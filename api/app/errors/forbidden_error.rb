class ForbiddenError < ApiError
  CODE = 1003

  def initialize(message = "You are not authorized to perform this action")
    super(message, code: CODE, status: :forbidden)
  end
end
