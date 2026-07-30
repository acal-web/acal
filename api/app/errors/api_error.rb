# Base class for domain errors rendered as {"code" => Integer, "message" => String}.
# Subclasses declare a CODE constant; the Flutter client mirrors it in an enum
# so the UI can key off `code` instead of parsing `message`.
class ApiError < StandardError
  attr_reader :code

  def initialize(message, code:)
    @code = code
    super(message)
  end
end
