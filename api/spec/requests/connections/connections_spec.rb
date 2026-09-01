require "rails_helper"

RSpec.describe "Connections", type: :request do
  def customer_json(customer)
    {
      "id" => customer.id,
      "name" => customer.name,
      "document" => customer.document,
      "membership_number" => customer.membership_number,
      "voter" => customer.voter,
      "legacy_id" => customer.legacy_id,
      "tags" => customer.tags,
      "customer_code" => customer.customer_code,
      "created_at" => customer.created_at.as_json,
      "updated_at" => customer.updated_at.as_json,
      "deleted_at" => customer.deleted_at
    }
  end

  def address_json(address)
    {
      "id" => address.id,
      "name" => address.name,
      "legacy_id" => address.legacy_id,
      "tags" => address.tags,
      "created_at" => address.created_at.as_json,
      "updated_at" => address.updated_at.as_json,
      "deleted_at" => address.deleted_at
    }
  end

  def category_json(category)
    {
      "id" => category.id,
      "name" => category.name,
      "description" => category.description,
      "group" => category.group,
      "has_water_meter" => category.has_water_meter,
      "water_price" => category.water_price.to_s,
      "membership_price" => category.membership_price.to_s,
      "legacy_id" => category.legacy_id,
      "tags" => category.tags,
      "created_at" => category.created_at.as_json,
      "updated_at" => category.updated_at.as_json,
      "deleted_at" => category.deleted_at
    }
  end

  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category) }
  let(:valid_params) do
    { connection: { customer_id: customer.id, address_id: address.id, category_id: category.id, number: 1 } }
  end

  describe "GET /connections/:id" do
    context "when successful" do
      it "returns the connection with nested data" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]

        get "/connections/#{id}"

        connection = Connection.find(id)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "id" => connection.id,
          "customer_id" => customer.id,
          "address_id" => address.id,
          "category_id" => category.id,
          "number" => 1,
          "letter" => nil,
          "active" => true,
          "legacy_id" => nil,
          "membership_date" => nil,
          "exclusively_member" => false,
          "tags" => [],
          "created_at" => connection.created_at.as_json,
          "updated_at" => connection.updated_at.as_json,
          "deleted_at" => nil,
          "customer" => customer_json(customer),
          "address" => address_json(address),
          "category" => category_json(category)
        )
      end

      it "still returns the full customer, address and category even after they're soft deleted" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]
        customer.soft_delete!
        address.soft_delete!
        category.soft_delete!

        get "/connections/#{id}"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body["customer"].except("deleted_at")).to eq(customer_json(customer.reload).except("deleted_at"))
        expect(body["address"].except("deleted_at")).to eq(address_json(address.reload).except("deleted_at"))
        expect(body["category"].except("deleted_at")).to eq(category_json(category.reload).except("deleted_at"))
        expect(body["customer"]["deleted_at"]).not_to be_nil
        expect(body["address"]["deleted_at"]).not_to be_nil
        expect(body["category"]["deleted_at"]).not_to be_nil
      end
    end

    context "when it fails" do
      it "returns not found for a nonexistent connection" do
        get "/connections/00000000-0000-0000-0000-000000000000"

        expect(response).to have_http_status(:not_found)
      end

      it "returns not found for a soft deleted connection" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]
        delete "/connections/#{id}"

        get "/connections/#{id}"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
