module AuthenticationHelper
  def sign_in_as(user)
    token = JwtToken.encode(user.id)
    @auth_headers = { "Authorization" => "Bearer #{token}" }
  end

  def sign_in_as_customer(customer)
    token = JwtToken.encode(customer.id, key: :customer_id)
    @auth_headers = { "Authorization" => "Bearer #{token}" }
  end

  def auth_headers
    @auth_headers || {}
  end
end

RSpec.configure do |c|
  c.include AuthenticationHelper, type: :request
end
