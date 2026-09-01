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

      it "filters by status=active (ativas)" do
        create(:connection, customer: customer, address: address, category: category, active: true)
        inactive_address = create(:address, name: "Inactive Street")
        create(:connection, customer: create(:customer), address: inactive_address, category: category, active: false)
        deleted_address = create(:address, name: "Deleted Street")
        deleted_conn = create(:connection, customer: create(:customer), address: deleted_address, category: category, active: true)
        deleted_conn.soft_delete!

        get "/connections", params: { status: "active" }

        expect(response.parsed_body["totalElements"]).to eq(1)
        expect(response.parsed_body["content"].map { |c| c["address_id"] }).to eq([ address.id ])
      end

      it "filters by status=inactive (inativos)" do
        create(:connection, customer: customer, address: address, category: category, active: true)
        inactive_address = create(:address, name: "Inactive Street")
        create(:connection, customer: create(:customer), address: inactive_address, category: category, active: false)
        deleted_address = create(:address, name: "Deleted Street")
        deleted_conn = create(:connection, customer: create(:customer), address: deleted_address, category: category, active: false)
        deleted_conn.soft_delete!

        get "/connections", params: { status: "inactive" }

        expect(response.parsed_body["totalElements"]).to eq(1)
        expect(response.parsed_body["content"].map { |c| c["address_id"] }).to eq([ inactive_address.id ])
      end

      it "filters by status=deleted (excluidos)" do
        create(:connection, customer: customer, address: address, category: category, active: true)
        inactive_address = create(:address, name: "Inactive Street")
        create(:connection, customer: create(:customer), address: inactive_address, category: category, active: false)
        deleted_address_1 = create(:address, name: "Deleted Street 1")
        deleted_conn_1 = create(:connection, customer: create(:customer), address: deleted_address_1, category: category, active: true)
        deleted_conn_1.soft_delete!
        deleted_address_2 = create(:address, name: "Deleted Street 2")
        deleted_conn_2 = create(:connection, customer: create(:customer), address: deleted_address_2, category: category, active: false)
        deleted_conn_2.soft_delete!

        get "/connections", params: { status: "deleted" }

        expect(response.parsed_body["totalElements"]).to eq(2)
        expect(response.parsed_body["content"].map { |c| c["address_id"] }.sort).to eq([ deleted_address_1.id, deleted_address_2.id ].sort)
      end

      it "filters by status=all (todos)" do
        create(:connection, customer: customer, address: address, category: category, active: true)
        inactive_address = create(:address, name: "Inactive Street")
        create(:connection, customer: create(:customer), address: inactive_address, category: category, active: false)
        deleted_address = create(:address, name: "Deleted Street")
        deleted_conn = create(:connection, customer: create(:customer), address: deleted_address, category: category, active: true)
        deleted_conn.soft_delete!

        get "/connections", params: { status: "all" }

        expect(response.parsed_body["totalElements"]).to eq(3)
        expect(response.parsed_body["content"].map { |c| c["address_id"] }.sort).to eq([ address.id, inactive_address.id, deleted_address.id ].sort)
      end

      it "combines multiple filters" do
        create(:connection, customer: customer, address: address, category: category)
        create(:connection, customer: create(:customer), address: create(:address, name: "Second Avenue"), category: category)

        get "/connections", params: { customer_name: customer.name[0, 6], address_name: address.name[0, 4] }

        expect(response.parsed_body["content"].map { |c| c["customer_id"] }).to eq([ customer.id ])
      end

      context "when sorting" do
        before do
          create(:connection,
            customer: create(:customer, name: "Ana"), address: create(:address, name: "Rua A"),
            category: create(:category, name: "Categoria A"), number: 30)
          create(:connection,
            customer: create(:customer, name: "Beto"), address: create(:address, name: "Rua B"),
            category: create(:category, name: "Categoria B"), number: 10)
          create(:connection,
            customer: create(:customer, name: "Carla"), address: create(:address, name: "Rua C"),
            category: create(:category, name: "Categoria C"), number: 20)
        end

        def numbers_in_response
          response.parsed_body["content"].map { |c| c["number"] }
        end

        it "sorts by customer_name, address_name, number by default" do
          get "/connections"

          expect(numbers_in_response).to eq([ 30, 10, 20 ])
        end

        it "sorts by address_name" do
          get "/connections", params: { sort_by: "address_name" }
          expect(numbers_in_response).to eq([ 30, 10, 20 ])

          get "/connections", params: { sort_by: "address_name", sort_direction: "desc" }
          expect(numbers_in_response).to eq([ 20, 10, 30 ])
        end

        it "sorts by number" do
          get "/connections", params: { sort_by: "number" }
          expect(numbers_in_response).to eq([ 10, 20, 30 ])

          get "/connections", params: { sort_by: "number", sort_direction: "desc" }
          expect(numbers_in_response).to eq([ 30, 20, 10 ])
        end

        it "sorts by customer_name" do
          get "/connections", params: { sort_by: "customer_name" }
          expect(numbers_in_response).to eq([ 30, 10, 20 ])

          get "/connections", params: { sort_by: "customer_name", sort_direction: "desc" }
          expect(numbers_in_response).to eq([ 20, 10, 30 ])
        end

        it "sorts by category_name" do
          get "/connections", params: { sort_by: "category_name" }
          expect(numbers_in_response).to eq([ 30, 10, 20 ])

          get "/connections", params: { sort_by: "category_name", sort_direction: "desc" }
          expect(numbers_in_response).to eq([ 20, 10, 30 ])
        end

        it "falls back to ascending for an unrecognized sort_direction" do
          get "/connections", params: { sort_by: "number", sort_direction: "sideways" }

          expect(numbers_in_response).to eq([ 10, 20, 30 ])
        end

        it "falls back to the default order for an unrecognized sort_by" do
          get "/connections", params: { sort_by: "favorite_color" }

          expect(numbers_in_response).to eq([ 30, 10, 20 ])
        end
      end
    end
  end
end
