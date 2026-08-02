require "rails_helper"

RSpec.describe "Connections", type: :request do
  def valid_cpf(base)
    digits = base.to_s.rjust(9, "0")
    d1 = document_check_digit(digits, (10).downto(2).to_a)
    d2 = document_check_digit(digits + d1.to_s, (11).downto(2).to_a)
    "#{digits}#{d1}#{d2}"
  end

  def document_check_digit(digits, weights)
    sum = digits.chars.each_with_index.sum { |d, i| d.to_i * weights[i] }
    remainder = sum % 11
    remainder < 2 ? 0 : 11 - remainder
  end

  def create_customer(name: "Fulano de Tal", document_base: 100000000)
    Customer.create!(name: name, document: valid_cpf(document_base), membership_number: rand(1..100_000))
  end

  def create_address(name: "Main Street")
    Address.create!(kind: "home", name: name)
  end

  def create_category(name: "Padrão")
    Category.create!(name: name, group: "efetivo", water_price: 0, membership_price: 0)
  end

  def customer_json(customer)
    {
      "id" => customer.id,
      "name" => customer.name,
      "document" => customer.document,
      "membership_number" => customer.membership_number,
      "voter" => customer.voter,
      "legacy_id" => customer.legacy_id,
      "created_at" => customer.created_at.as_json,
      "updated_at" => customer.updated_at.as_json,
      "deleted_at" => customer.deleted_at
    }
  end

  def address_json(address)
    {
      "id" => address.id,
      "kind" => address.kind,
      "name" => address.name,
      "legacy_id" => address.legacy_id,
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
      "created_at" => category.created_at.as_json,
      "updated_at" => category.updated_at.as_json,
      "deleted_at" => category.deleted_at
    }
  end

  let(:customer) { create_customer }
  let(:address) { create_address }
  let(:category) { create_category }
  let(:valid_params) do
    { connection: { customer_id: customer.id, address_id: address.id, category_id: category.id } }
  end

  describe "GET /connections" do
    context "when successful" do
      it "returns a paginated page of connections" do
        13.times { |i| Connection.create!(customer: create_customer(document_base: 200000000 + i), address: create_address(name: "Street #{i}"), category: category) }

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

      it "excludes soft deleted connections" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]
        delete "/connections/#{id}"

        get "/connections"

        expect(response.parsed_body["content"]).to eq([])
      end

      it "filters by customer name" do
        other = create_customer(name: "Ciclano da Silva", document_base: 300000000)
        Connection.create!(customer: customer, address: address, category: category)
        Connection.create!(customer: other, address: create_address(name: "Other Street"), category: category)

        get "/connections", params: { customer_name: customer.name[0, 6] }

        expect(response.parsed_body["content"].map { |c| c["customer_id"] }).to eq([ customer.id ])
      end

      it "filters by customer document" do
        Connection.create!(customer: customer, address: address, category: category)
        other = create_customer(name: "Ciclano", document_base: 300000000)
        Connection.create!(customer: other, address: create_address(name: "Other Street"), category: category)

        get "/connections", params: { customer_document: customer.document[0, 6] }

        expect(response.parsed_body["content"].map { |c| c["customer_id"] }).to eq([ customer.id ])
      end

      it "filters by address name" do
        Connection.create!(customer: customer, address: address, category: category)
        Connection.create!(customer: create_customer(document_base: 300000000), address: create_address(name: "Second Avenue"), category: category)

        get "/connections", params: { address_name: address.name[0, 4] }

        expect(response.parsed_body["content"].map { |c| c["address_id"] }).to eq([ address.id ])
      end

      it "filters by category_id" do
        other_category = create_category(name: "Especial")
        Connection.create!(customer: customer, address: address, category: category)
        Connection.create!(customer: create_customer(document_base: 300000000), address: create_address(name: "Second Avenue"), category: other_category)

        get "/connections", params: { category_id: category.id }

        expect(response.parsed_body["content"].map { |c| c["category_id"] }).to eq([ category.id ])
      end

      it "filters by active status" do
        Connection.create!(customer: customer, address: address, category: category, active: true)
        ended_address = create_address(name: "Ended Street")
        Connection.create!(customer: create_customer(document_base: 300000000), address: ended_address, category: category, active: false)

        get "/connections", params: { active: "false" }

        expect(response.parsed_body["content"].map { |c| c["address_id"] }).to eq([ ended_address.id ])
      end

      it "combines multiple filters" do
        Connection.create!(customer: customer, address: address, category: category)
        Connection.create!(customer: create_customer(document_base: 300000000), address: create_address(name: "Second Avenue"), category: category)

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
          "active" => true,
          "legacy_id" => nil,
          "created_at" => connection.created_at.as_json,
          "updated_at" => connection.updated_at.as_json,
          "deleted_at" => nil,
          "customer" => customer_json(customer),
          "address" => address_json(address),
          "category" => category_json(category)
        )
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

      it "allows creating a new connection for an address whose previous connection was ended" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]
        patch "/connections/#{id}", params: { connection: valid_params[:connection].merge(active: false) }

        new_customer = create_customer(name: "Ciclano", document_base: 300000000)

        expect {
          post "/connections", params: { connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id } }
        }.to change(Connection, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["active"]).to eq(true)
      end

      it "allows creating a new connection for an address whose previous connection was soft deleted" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]
        delete "/connections/#{id}"

        new_customer = create_customer(name: "Ciclano", document_base: 300000000)

        expect {
          post "/connections", params: { connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id } }
        }.to change(Connection, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "when it fails" do
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

      it "rejects a new active connection when the address already has an active connection" do
        post "/connections", params: valid_params

        new_customer = create_customer(name: "Ciclano", document_base: 300000000)

        expect {
          post "/connections", params: { connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id } }
        }.not_to change(Connection, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("address_id" => [ "already has an active connection" ])
      end
    end
  end

  describe "PATCH /connections/:id" do
    context "when successful" do
      it "updates the connection" do
        post "/connections", params: valid_params
        id = response.parsed_body["id"]
        new_category = create_category(name: "Especial")

        patch "/connections/#{id}", params: { connection: valid_params[:connection].merge(category_id: new_category.id) }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["category_id"]).to eq(new_category.id)
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
      it "rejects reactivating a connection when the address already has another active connection" do
        post "/connections", params: valid_params
        first_id = response.parsed_body["id"]
        patch "/connections/#{first_id}", params: { connection: valid_params[:connection].merge(active: false) }

        new_customer = create_customer(name: "Ciclano", document_base: 300000000)
        post "/connections", params: { connection: { customer_id: new_customer.id, address_id: address.id, category_id: category.id } }

        patch "/connections/#{first_id}", params: { connection: valid_params[:connection].merge(active: true) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("address_id" => [ "already has an active connection" ])
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
