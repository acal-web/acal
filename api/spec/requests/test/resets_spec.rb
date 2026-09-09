require "rails_helper"

RSpec.describe "Test::Resets", type: :request do
  describe "POST /test/reset" do
    it "resets the database for an administrador" do
      create(:customer)

      post "/test/reset"

      expect(response).to have_http_status(:no_content)
      expect(Customer.count).to eq(0)
    end

    it "returns forbidden for a user without test:data:reset" do
      sign_in_as(create(:user, :financeiro_secretaria))

      post "/test/reset"

      expect(response).to have_http_status(:forbidden)
    end
  end
end
