require "rails_helper"

RSpec.describe "Addresses", type: :request do
  let(:valid_params) { { address: { name: "Rua Main Street" } } }

  describe "GET /addresses/:id" do
    context "when successful" do
      it "returns the address" do
        post "/addresses", params: valid_params
        id = response.parsed_body["id"]

        get "/addresses/#{id}"

        address = Address.find(id)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "id" => address.id,
          "name" => "Rua Main Street",
          "created_at" => address.created_at.as_json,
          "updated_at" => address.updated_at.as_json,
          "deleted_at" => nil,
          "legacy_id" => nil,
          "tags" => []
        )
      end
    end

    context "when it fails" do
      it "returns not found for a nonexistent address" do
        get "/addresses/00000000-0000-0000-0000-000000000000"

        expect(response).to have_http_status(:not_found)
      end

      it "returns not found for a soft deleted address" do
        post "/addresses", params: valid_params
        id = response.parsed_body["id"]
        delete "/addresses/#{id}"

        get "/addresses/#{id}"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
