require "rails_helper"

RSpec.describe "Addresses", type: :request do
  let(:valid_params) { { address: { name: "Rua Main Street" } } }

  describe "DELETE /addresses/:id" do
    it "soft deletes the address instead of removing it" do
      post "/addresses", params: valid_params
      address = Address.last

      expect {
        delete "/addresses/#{address.id}"
      }.not_to change(Address.unscoped, :count)

      expect(response).to have_http_status(:no_content)
      expect(address.reload.deleted_at).not_to be_nil
    end

    it "excludes the address from the default scope" do
      post "/addresses", params: valid_params
      address = Address.last

      delete "/addresses/#{address.id}"

      expect(Address.exists?(address.id)).to be(false)
    end

    it "returns not found for a nonexistent address" do
      delete "/addresses/00000000-0000-0000-0000-000000000000"

      expect(response).to have_http_status(:not_found)
    end

    context "when unauthorized" do
      it "returns forbidden for a user without addresses:manage" do
        post "/addresses", params: valid_params
        address = Address.last
        sign_in_as(create(:user, role: "tesoureiro"))

        delete "/addresses/#{address.id}"

        expect(response).to have_http_status(:forbidden)
        expect(address.reload.deleted_at).to be_nil
      end
    end
  end
end
