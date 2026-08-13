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

  describe "GET /connections" do
    context "when successful" do
      it "returns a paginated page of connections" do
        13.times { create(:connection, customer: create(:customer), address: create(:address), category: category) }

        get "/connections"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body["content"].size).to eq(10)
        expect(body.except("content")).to eq(
          "pageable" => { "pageNumber" => 0, "pageSize" => 10, "offset" => 0 },
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

      it "embeds the full nested customer, address and category" do
        post "/connections", params: valid_params

        get "/connections"

        row = response.parsed_body["content"].first
        expect(row["customer"]).to eq(customer_json(customer))
        expect(row["address"]).to eq(address_json(address))
        expect(row["category"]).to eq(category_json(category))
      end

      it "still embeds the full customer, address and category even after they're soft deleted" do
        post "/connections", params: valid_params
        customer.soft_delete!
        address.soft_delete!
        category.soft_delete!

        get "/connections"

        row = response.parsed_body["content"].first
        expect(row["customer"].except("deleted_at")).to eq(customer_json(customer.reload).except("deleted_at"))
        expect(row["address"].except("deleted_at")).to eq(address_json(address.reload).except("deleted_at"))
        expect(row["category"].except("deleted_at")).to eq(category_json(category.reload).except("deleted_at"))
        expect(row["customer"]["deleted_at"]).not_to be_nil
        expect(row["address"]["deleted_at"]).not_to be_nil
        expect(row["category"]["deleted_at"]).not_to be_nil
      end

      it "excludes soft deleted connections" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]
        delete "/connections/#{id}"

        get "/connections"

        expect(response.parsed_body["content"]).to eq([])
      end

      it "filters by customer name" do
        other = create(:customer, name: "Ciclano da Silva")
        create(:connection, customer: customer, address: address, category: category)
        create(:connection, customer: other, address: create(:address), category: category)

        get "/connections", params: { customer_name: customer.name[0, 6] }

        expect(response.parsed_body["content"].map { |c| c["customer_id"] }).to eq([ customer.id ])
      end

      it "filters by customer document" do
        create(:connection, customer: customer, address: address, category: category)
        other = create(:customer, name: "Ciclano", document: DocumentGenerator.cpf(300_000_000))
        create(:connection, customer: other, address: create(:address), category: category)

        get "/connections", params: { customer_document: customer.document[0, 6] }

        expect(response.parsed_body["content"].map { |c| c["customer_id"] }).to eq([ customer.id ])
      end

      it "filters by customer_id" do
        create(:connection, customer: customer, address: address, category: category)
        other = create(:customer, name: "Ciclano")
        create(:connection, customer: other, address: create(:address), category: category)

        get "/connections", params: { customer_id: customer.id }

        expect(response.parsed_body["content"].map { |c| c["customer_id"] }).to eq([ customer.id ])
      end

      it "filters by address name" do
        create(:connection, customer: customer, address: address, category: category)
        create(:connection, customer: create(:customer), address: create(:address, name: "Second Avenue"), category: category)

        get "/connections", params: { address_name: address.name[0, 4] }

        expect(response.parsed_body["content"].map { |c| c["address_id"] }).to eq([ address.id ])
      end

      it "filters by category_id" do
        other_category = create(:category, name: "Especial")
        create(:connection, customer: customer, address: address, category: category)
        create(:connection, customer: create(:customer), address: create(:address), category: other_category)

        get "/connections", params: { category_id: category.id }

        expect(response.parsed_body["content"].map { |c| c["category_id"] }).to eq([ category.id ])
      end

      it "excludes connections whose category was soft deleted, even when filtering by that category_id" do
        create(:connection, customer: customer, address: address, category: category)
        category.soft_delete!

        get "/connections", params: { category_id: category.id }

        expect(response.parsed_body["content"]).to eq([])
      end

      it "filters by active status" do
        create(:connection, customer: customer, address: address, category: category, active: true)
        ended_address = create(:address, name: "Ended Street")
        create(:connection, customer: create(:customer), address: ended_address, category: category, active: false)

        get "/connections", params: { active: "false" }

        expect(response.parsed_body["content"].map { |c| c["address_id"] }).to eq([ ended_address.id ])
      end

      it "combines multiple filters" do
        create(:connection, customer: customer, address: address, category: category)
        create(:connection, customer: create(:customer), address: create(:address, name: "Second Avenue"), category: category)

        get "/connections", params: { customer_name: customer.name[0, 6], address_name: address.name[0, 4] }

        expect(response.parsed_body["content"].map { |c| c["customer_id"] }).to eq([ customer.id ])
      end
    end
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

      it "rejects a second connection with the same address and number, with no letter on either" do
        post "/connections", params: valid_params.deep_merge(connection: { active: false })

        new_customer = create(:customer, name: "Ciclano")
        post "/connections", params: { connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id, number: 1, active: false } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Connection already exists")
      end

      it "rejects a second connection with the same address, number and letter" do
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
        # Database unique index constraint is hit, resulting in a RecordNotUnique error
        expect(response.parsed_body["code"]).to eq(1001)
        expect(response.parsed_body["message"]).to include("already exists")
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

  describe "PATCH /connections/:id" do
    context "when successful" do
      it "updates the connection" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]
        new_category = create(:category, name: "Especial")

        patch "/connections/#{id}", params: { connection: valid_params[:connection].merge(category_id: new_category.id) }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["category_id"]).to eq(new_category.id)
      end

      it "updates the membership_date and exclusively_member flag" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]

        patch "/connections/#{id}", params: {
          connection: valid_params[:connection].merge(membership_date: "2024-03-15", exclusively_member: true)
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["membership_date"]).to eq("2024-03-15")
        expect(response.parsed_body["exclusively_member"]).to eq(true)
      end

      it "ends a connection by setting active to false without blocking itself" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]

        patch "/connections/#{id}", params: { connection: valid_params[:connection].merge(active: false) }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["active"]).to eq(false)
      end

      it "allows re-saving an active connection unchanged" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]

        patch "/connections/#{id}", params: { connection: valid_params[:connection] }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["active"]).to eq(true)
      end
    end

    context "when it fails" do
      it "allows reactivating a connection when the address has another active connection with a different number" do
        post "/connections", params: valid_params
        first_id = response.parsed_body["id"]
        patch "/connections/#{first_id}", params: { connection: valid_params[:connection].merge(active: false) }

        new_customer = create(:customer, name: "Ciclano")
        post "/connections", params: { connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id, number: 2 } }

        expect {
          patch "/connections/#{first_id}", params: { connection: valid_params[:connection].merge(active: true) }
        }.to change { Connection.find(first_id).active }.from(false).to(true)

        expect(response).to have_http_status(:ok)
      end

      it "rejects reactivating a connection when the customer is already efetivo in another active connection" do
        post "/connections", params: valid_params
        first_id = response.parsed_body["id"]
        patch "/connections/#{first_id}", params: { connection: valid_params[:connection].merge(active: false) }

        new_address = create(:address, name: "Second Street")
        post "/connections", params: { connection: { customer_id: customer.id, address_id: new_address.id, category_id: category.id, number: 1 } }

        patch "/connections/#{first_id}", params: { connection: valid_params[:connection].merge(active: true) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("customer_id" => [ "already has an active connection as efetivo" ])
      end
    end
  end

  describe "DELETE /connections/:id" do
    context "when successful" do
      it "soft deletes the connection instead of removing it" do
        post "/connections", params: valid_params
        connection = Connection.last

        expect {
          delete "/connections/#{connection.id}"
        }.not_to change(Connection.unscoped, :count)

        expect(response).to have_http_status(:no_content)
        expect(connection.reload.deleted_at).not_to be_nil
      end

      it "excludes the connection from the default scope" do
        post "/connections", params: valid_params
        connection = Connection.last

        delete "/connections/#{connection.id}"

        expect(Connection.exists?(connection.id)).to be(false)
      end
    end
  end
end
