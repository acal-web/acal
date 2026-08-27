module AuthenticationHelper
  def sign_in_as(user)
    token = JwtToken.encode(user.id, group: user.role)
    @auth_headers = { "Authorization" => "Bearer #{token}" }
  end

  def sign_in_as_customer(customer)
    sign_in_as(customer.user)
  end

  def auth_headers
    @auth_headers || {}
  end
end

RSpec.configure do |c|
  c.include AuthenticationHelper, type: :request
end
