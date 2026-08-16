# Base class for domain errors rendered as {"code" => Integer, "message" => String}.
# Subclasses declare a CODE constant; the Flutter client mirrors it in an enum
# so the UI can key off `code` instead of parsing `message`.
class ApiError < StandardError
  attr_reader :code, :status

  def initialize(message, code:, status: :unprocessable_content)
    @code = code
    @status = status
    super(message)
  end
end
