require "rails_helper"

RSpec.describe "Addresses", type: :request do
  let(:valid_params) { { address: { kind: "home", name: "Main Street" } } }

  describe "POST /addresses" do
    context "when successful" do
      it "creates an address" do
        expect {
          post "/addresses", params: valid_params
        }.to change(Address, :count).by(1)

        address = Address.last

        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to eq(
          "id" => address.id,
          "kind" => "home",
          "name" => "Main Street",
          "created_at" => address.created_at.as_json,
          "updated_at" => address.updated_at.as_json,
          "deleted_at" => nil
        )
      end
    end

    context "when it fails" do
      it "rejects a request without a kind" do
        post "/addresses", params: { address: valid_params[:address].except(:kind) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("kind" => [ "can't be blank" ])
      end

      it "rejects a request without a name" do
        post "/addresses", params: { address: valid_params[:address].except(:name) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("name" => [ "can't be blank", "is too short (minimum is 3 characters)" ])
      end

      it "rejects a duplicate address" do
        post "/addresses", params: valid_params

        expect {
          post "/addresses", params: valid_params
        }.not_to change(Address, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("name" => [ "has already been taken" ])
      end

      it "rejects a duplicate address with a different case" do
        post "/addresses", params: valid_params

        expect {
          post "/addresses", params: { address: { kind: "HOME", name: "MAIN STREET" } }
        }.not_to change(Address, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("name" => [ "has already been taken" ])
      end
    end
  end
end
