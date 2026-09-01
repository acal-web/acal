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
  end
end
