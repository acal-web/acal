require "rails_helper"

RSpec.describe "Addresses", type: :request do
  let(:valid_params) { { address: { name: "Rua Main Street" } } }

  describe "PATCH /addresses/:id/restore" do
    context "when successful" do
      it "restores a soft deleted address" do
        address = create(:address, **valid_params[:address].merge(deleted_at: Time.current))

        patch "/addresses/#{address.id}/restore"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["deleted_at"]).to be_nil
        expect(address.reload.deleted_at).to be_nil
      end
    end

    context "when it fails" do
      it "returns not found for a nonexistent address" do
        patch "/addresses/00000000-0000-0000-0000-000000000000/restore"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthorized" do
      it "returns forbidden for a user without addresses:manage" do
        address = create(:address, **valid_params[:address].merge(deleted_at: Time.current))
        sign_in_as(create(:user, role: "tesoureiro"))

        patch "/addresses/#{address.id}/restore"

        expect(response).to have_http_status(:forbidden)
        expect(address.reload.deleted_at).not_to be_nil
      end
    end
  end
end
