require "rails_helper"

RSpec.describe "Version", type: :request do
  describe "GET /version" do
    it "returns the API version from the VERSION file" do
      get "/version"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["version"]).to eq(File.read(Rails.root.join("VERSION")).strip)
    end

    it "returns 401 without a token", :skip_auth do
      get "/version"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
