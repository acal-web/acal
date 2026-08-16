require "rails_helper"

RSpec.describe "Addresses", type: :request do
  let(:valid_params) { { address: { name: "Rua Main Street" } } }

  describe "Listing & Filtering" do
    describe "GET /addresses" do
      context "pagination" do
        it "returns a paginated page of addresses" do
          create_list(:address, 13)

          get "/addresses"

          expect(response).to have_http_status(:ok)
          body = response.parsed_body
          expect(body["content"].size).to eq(10)
          expect(body.except("content")).to eq(
            "pageable" => { "pageNumber" => 0, "pageSize" => 10, "offset" => 0 },
            "hasNextPage" => true,
            "totalPages" => 2,
            "totalElements" => 13,
            "last" => false,
            "first" => true,
            "size" => 10,
            "number" => 0,
            "numberOfElements" => 10,
            "empty" => false
          )
        end

        it "respects the page and size params" do
          create_list(:address, 25)

          get "/addresses", params: { page: 1, size: 10 }

          expect(response).to have_http_status(:ok)
          body = response.parsed_body
          expect(body["content"].size).to eq(10)
          expect(body.except("content")).to eq(
            "pageable" => { "pageNumber" => 1, "pageSize" => 10, "offset" => 10 },
            "hasNextPage" => true,
            "totalPages" => 3,
            "totalElements" => 25,
            "last" => false,
            "first" => false,
            "size" => 10,
            "number" => 1,
            "numberOfElements" => 10,
            "empty" => false
          )
        end
      end

      context "filtering" do
        it "filters by name" do
          create(:address, name: "Rua Main Street")
          create(:address, name: "Avenida Second Avenue")

          get "/addresses", params: { name: "main" }

          expect(response.parsed_body["content"].map { |a| a["name"] }).to eq([ "Rua Main Street" ])
        end
      end

      context "soft-deletion" do
        it "excludes soft deleted addresses" do
          post "/addresses", params: valid_params
          id = response.parsed_body["id"]
          delete "/addresses/#{id}"

          get "/addresses"

          expect(response.parsed_body["content"]).to eq([])
        end
      end
    end
  end

  describe "Retrieving" do
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

  describe "Creating" do
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
    end
  end

  describe "Updating" do
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

  describe "Deleting" do
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
end
