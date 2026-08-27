require "rails_helper"

RSpec.describe "Portal::Devices", type: :request do
  let(:customer) { create(:customer) }

  before { sign_in_as_customer(customer) }

  describe "POST /portal/devices" do
    it "registers a device for the authenticated customer" do
      post "/portal/devices", params: {
        device: {
          platform: "android",
          push_token: "fcm-token-1",
          device_model: "Moto G",
          os_version: "Android 13",
          app_version: "0.1.1"
        }
      }

      expect(response).to have_http_status(:created)
      device = Device.find(response.parsed_body["id"])
      expect(device.owner).to eq(customer)
      expect(device.push_token).to eq("fcm-token-1")
    end

    it "returns 401 without a token", :skip_auth do
      post "/portal/devices", params: { device: { platform: "android" } }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 403 for a staff token (not the customer group)", :skip_auth do
      user = create(:user)
      token = JwtToken.encode(user.id, group: user.role)

      post "/portal/devices", params: { device: { platform: "android" } }, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
