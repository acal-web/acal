class DuplicateResourceError < ApiError
  CODE = 1001

  def initialize(message = "Resource already exists")
    super(message, code: CODE)
  end
end
