module AuthenticationHelper
  def sign_in_as(user)
    _, raw_token = Session.start_for!(user)
    @auth_headers = { "Authorization" => "Bearer #{raw_token}" }
  end

  def auth_headers
    @auth_headers || {}
  end
end

RSpec.configure do |c|
  c.include AuthenticationHelper, type: :request
end
