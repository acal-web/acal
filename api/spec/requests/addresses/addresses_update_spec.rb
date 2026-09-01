require "rails_helper"

RSpec.describe "Addresses", type: :request do
  let(:valid_params) { { address: { name: "Rua Main Street" } } }

  describe "PATCH /addresses/:id" do
    context "valid updates" do
      it "updates the address" do
        post "/addresses", params: valid_params
        id = response.parsed_body["id"]

        patch "/addresses/#{id}", params: { address: { name: "Avenida Second Street" } }

        address = Address.find(id)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "id" => address.id,
          "name" => "Avenida Second Street",
          "created_at" => address.created_at.as_json,
          "updated_at" => address.updated_at.as_json,
          "deleted_at" => nil,
          "legacy_id" => nil,
          "tags" => []
        )
      end
    end

    context "validation errors" do
      it "rejects a request without a name" do
        post "/addresses", params: valid_params
        id = response.parsed_body["id"]

        patch "/addresses/#{id}", params: { address: { name: nil } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("name" => [ "can't be blank", "is too short (minimum is 3 characters)" ])
      end
    end

    context "uniqueness constraints" do
      it "rejects updating to a duplicate address" do
        post "/addresses", params: valid_params
        post "/addresses", params: { address: { name: "Avenida Other Street" } }
        id = response.parsed_body["id"]

        patch "/addresses/#{id}", params: { address: { name: "Rua Main Street" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Address already exists")
      end

      it "rejects updating to a duplicate address with different case" do
        post "/addresses", params: valid_params
        post "/addresses", params: { address: { name: "Avenida Other Street" } }
        id = response.parsed_body["id"]

        patch "/addresses/#{id}", params: { address: { name: "RUA MAIN STREET" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Address already exists")
      end
    end
  end
end
