require "rails_helper"

RSpec.describe "Me", type: :request do
  describe "GET /me" do
    it "returns the current authenticated user" do
      user = create(:user, role: "administrador")
      sign_in_as(user)

      get "/me"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "id" => user.id,
        "username" => user.username,
        "name" => user.name,
        "role" => user.role,
        "created_at" => user.created_at.as_json,
        "updated_at" => user.updated_at.as_json
      )
    end

    it "works for any authenticated role, e.g. a customer" do
      customer = create(:customer)
      sign_in_as_customer(customer)

      get "/me"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["role"]).to eq("customer")
    end

    it "returns 401 without a token", :skip_auth do
      get "/me"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
