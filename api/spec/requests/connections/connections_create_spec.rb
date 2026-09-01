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

  describe "POST /connections" do
    context "when successful" do
      it "creates a connection, defaulting active to true" do
        expect {
          post "/connections", params: valid_params
        }.to change(Connection, :count).by(1)

        connection = Connection.last

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["id"]).to eq(connection.id)
        expect(response.parsed_body["active"]).to eq(true)
        expect(response.parsed_body["customer"]).to eq(customer_json(customer))
        expect(response.parsed_body["address"]).to eq(address_json(address))
        expect(response.parsed_body["category"]).to eq(category_json(category))
      end

      it "accepts and returns a legacy_id" do
        post "/connections", params: { connection: valid_params[:connection].merge(legacy_id: 123) }

        connection = Connection.last

        expect(response).to have_http_status(:created)
        expect(connection.legacy_id).to eq(123)
        expect(response.parsed_body["legacy_id"]).to eq(123)
      end

      it "accepts and returns a membership_date and exclusively_member flag, defaulting exclusively_member to false" do
        post "/connections", params: {
          connection: valid_params[:connection].merge(membership_date: "2024-03-15", exclusively_member: true)
        }

        connection = Connection.last

        expect(response).to have_http_status(:created)
        expect(connection.membership_date).to eq(Date.new(2024, 3, 15))
        expect(connection.exclusively_member).to eq(true)
        expect(response.parsed_body["membership_date"]).to eq("2024-03-15")
        expect(response.parsed_body["exclusively_member"]).to eq(true)
      end

      it "defaults exclusively_member to false and membership_date to nil when omitted" do
        post "/connections", params: valid_params

        expect(response.parsed_body["membership_date"]).to be_nil
        expect(response.parsed_body["exclusively_member"]).to eq(false)
      end

      it "allows creating a new connection for an address whose previous connection was ended" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]
        patch "/connections/#{id}", params: { connection: valid_params[:connection].merge(active: false) }

        new_customer = create(:customer, name: "Ciclano")

        expect {
          # The ended connection's row still exists (not deleted), so it
          # still holds number 1 on this address — the new one needs a
          # different number.
          post "/connections", params: { connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id, number: 2 } }
        }.to change(Connection, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["active"]).to eq(true)
      end

      it "allows a second connection with the same address and number when the letter differs" do
        post "/connections", params: valid_params.deep_merge(connection: { active: false })

        new_customer = create(:customer, name: "Ciclano")

        expect {
          post "/connections", params: {
            connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id, number: 1, letter: "A", active: false }
          }
        }.to change(Connection, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["letter"]).to eq("A")
      end

      it "allows creating a new connection for an address whose previous connection was soft deleted" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]
        delete "/connections/#{id}"

        new_customer = create(:customer, name: "Ciclano")

        expect {
          # Soft deleted, so it no longer occupies number 1 on this address.
          post "/connections", params: { connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id, number: 1 } }
        }.to change(Connection, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "when it fails" do
      it "rejects a request without a number" do
        post "/connections", params: { connection: valid_params[:connection].except(:number) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("number" => [ "can't be blank", "is not a number" ])
      end

      it "rejects a second connection with the same address and number, with no letter on either, via the DB unique index when both are inactive (model validation only runs for active connections)" do
        post "/connections", params: valid_params.deep_merge(connection: { active: false })

        new_customer = create(:customer, name: "Ciclano")
        post "/connections", params: { connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id, number: 1, active: false } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Connection already exists")
      end

      it "rejects a second connection with the same address, number and letter, via the DB unique index when both are inactive" do
        post "/connections", params: valid_params.deep_merge(connection: { letter: "A", active: false })

        new_customer = create(:customer, name: "Ciclano")
        post "/connections", params: {
          connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id, number: 1, letter: "A", active: false }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Connection already exists")
      end

      it "rejects a request without a customer" do
        post "/connections", params: { connection: valid_params[:connection].except(:customer_id) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("customer" => [ "must exist" ])
      end

      it "rejects a request without an address" do
        post "/connections", params: { connection: valid_params[:connection].except(:address_id) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("address" => [ "must exist" ])
      end

      it "rejects a request without a category" do
        post "/connections", params: { connection: valid_params[:connection].except(:category_id) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("category" => [ "must exist" ])
      end

      it "allows a new active connection on the same address when the number differs" do
        post "/connections", params: valid_params

        new_customer = create(:customer, name: "Ciclano")

        expect {
          post "/connections", params: { connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id, number: 2 } }
        }.to change(Connection, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "rejects a new active connection when the address already has an active connection with the same number and letter" do
        post "/connections", params: valid_params

        new_customer = create(:customer, name: "Ciclano")

        expect {
          post "/connections", params: { connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id, number: 1 } }
        }.not_to change(Connection, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("address_id" => [ "already has an active connection for this address number" ])
      end

      it "rejects a new active connection when the address already has an active connection with the same number and letter, both set" do
        post "/connections", params: valid_params.deep_merge(connection: { letter: "A" })

        new_customer = create(:customer, name: "Ciclano")

        expect {
          post "/connections", params: { connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id, number: 1, letter: "A" } }
        }.not_to change(Connection, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("address_id" => [ "already has an active connection for this address number" ])
      end

      it "rejects a new active connection when the customer is already efetivo in another active connection" do
        post "/connections", params: valid_params

        new_address = create(:address, name: "Second Street")

        expect {
          post "/connections", params: { connection: { customer_id: customer.id, address_id: new_address.id, category_id: category.id, number: 1 } }
        }.not_to change(Connection, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("customer_id" => [ "already has an active connection as efetivo" ])
      end

      it "allows the customer to have another active connection outside the efetivo group" do
        post "/connections", params: valid_params

        new_address = create(:address, name: "Second Street")
        temporario_category = create(:category, name: "Visitante", group: "temporario")

        expect {
          post "/connections", params: { connection: { customer_id: customer.id, address_id: new_address.id, category_id: temporario_category.id, number: 1 } }
        }.to change(Connection, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end
  end
end
