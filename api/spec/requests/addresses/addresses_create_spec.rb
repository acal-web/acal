require "rails_helper"

RSpec.describe "Addresses", type: :request do
  let(:valid_params) { { address: { name: "Rua Main Street" } } }

  describe "POST /addresses" do
    context "valid creation" do
      it "creates an address" do
        expect {
          post "/addresses", params: valid_params
        }.to change(Address, :count).by(1)

        address = Address.last

        expect(response).to have_http_status(:created)
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

      it "accepts and returns a legacy_id" do
        post "/addresses", params: { address: valid_params[:address].merge(legacy_id: 123) }

        address = Address.last

        expect(response).to have_http_status(:created)
        expect(address.legacy_id).to eq(123)
        expect(response.parsed_body["legacy_id"]).to eq(123)
      end

      it "strips leading and trailing whitespace from the name" do
        post "/addresses", params: { address: valid_params[:address].merge(name: "  Rua Main Street  ") }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("Rua Main Street")
      end
    end

    context "validation errors" do
      it "rejects a request without a name" do
        post "/addresses", params: { address: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("name" => [ "can't be blank", "is too short (minimum is 3 characters)" ])
      end
    end

    context "uniqueness constraints" do
      it "rejects a duplicate address" do
        post "/addresses", params: valid_params

        expect {
          post "/addresses", params: valid_params
        }.not_to change(Address, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Address already exists")
      end

      it "rejects a duplicate address with different case" do
        post "/addresses", params: valid_params

        expect {
          post "/addresses", params: { address: { name: "RUA MAIN STREET" } }
        }.not_to change(Address, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq(
          "code" => 1001,
          "message" => "Address already exists"
        )
      end

      it "rejects recreating a soft-deleted address with the same name" do
        post "/addresses", params: valid_params
        id = response.parsed_body["id"]
        delete "/addresses/#{id}"

        expect {
          post "/addresses", params: valid_params
        }.not_to change(Address, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Address already exists")
      end
    end

    context "when unauthorized" do
      it "returns forbidden for a user without addresses:manage" do
        sign_in_as(create(:user, role: "tesoureiro"))

        expect {
          post "/addresses", params: valid_params
        }.not_to change(Address, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
