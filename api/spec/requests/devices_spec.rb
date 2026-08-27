require "rails_helper"

RSpec.describe "Devices", type: :request do
  let(:user) { create(:user) }

  before { sign_in_as(user) }

  describe "POST /devices" do
    it "registers a device for the authenticated user" do
      post "/devices", params: {
        device: {
          platform: "android",
          push_token: "fcm-token-1",
          device_model: "Pixel 7",
          os_version: "Android 14",
          app_version: "0.1.1"
        }
      }

      expect(response).to have_http_status(:created)
      device = Device.find(response.parsed_body["id"])
      expect(device.owner).to eq(user)
      expect(device.push_token).to eq("fcm-token-1")
      expect(device.device_model).to eq("Pixel 7")
      expect(device.last_seen_at).to be_present
    end

    it "works without a push_token (Firebase not configured yet)" do
      post "/devices", params: { device: { platform: "android" } }

      expect(response).to have_http_status(:created)
      expect(Device.find(response.parsed_body["id"]).push_token).to be_nil
    end

    it "reassigns an existing push_token to the new owner instead of duplicating" do
      other_user = create(:user)
      existing = create(:device, owner: other_user, platform: "android", push_token: "shared-token")

      post "/devices", params: { device: { platform: "android", push_token: "shared-token" } }

      expect(response).to have_http_status(:created)
      expect(Device.count).to eq(1)
      expect(existing.reload.owner).to eq(user)
    end

    it "returns 401 without a token", :skip_auth do
      post "/devices", params: { device: { platform: "android" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
