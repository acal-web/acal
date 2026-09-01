require "rails_helper"

RSpec.describe "Customers", type: :request do
  let(:valid_document) { DocumentGenerator.cpf(123_456_789) }
  let(:valid_params) do
    {
      customer: {
        name: "Fulano de Tal",
        document: valid_document,
        membership_number: 42,
        voter: true
      }
    }
  end

  describe "GET /customers" do
    context "when successful" do
      it "returns a paginated page of customers" do
        create_list(:customer, 13)

        get "/customers"

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

      it "excludes soft deleted customers" do
        post "/customers", params: valid_params
        id = response.parsed_body["id"]
        delete "/customers/#{id}"

        get "/customers"

        expect(response.parsed_body["content"]).to eq([])
      end

      it "filters by name" do
        create(:customer, name: "Fulano de Tal")
        create(:customer, name: "Ciclano da Silva")

        get "/customers", params: { name: "fulano" }

        expect(response.parsed_body["content"].map { |c| c["name"] }).to eq([ "Fulano de Tal" ])
      end

      it "filters by document" do
        create(:customer, name: "Fulano de Tal", document: DocumentGenerator.cpf(111_222_333))
        target = create(:customer, name: "Ciclano da Silva", document: DocumentGenerator.cpf(444_555_666))

        get "/customers", params: { document: target.document[0, 6] }

        expect(response.parsed_body["content"].map { |c| c["name"] }).to eq([ "Ciclano da Silva" ])
      end

      it "combines name and document filters" do
        target = create(:customer, name: "Fulano de Tal", document: DocumentGenerator.cpf(111_222_333))
        create(:customer, name: "Fulano Segundo", document: DocumentGenerator.cpf(444_555_666))

        get "/customers", params: { name: "fulano", document: target.document[0, 6] }

        expect(response.parsed_body["content"].map { |c| c["name"] }).to eq([ "Fulano de Tal" ])
      end

      it "sorts by name ascending" do
        create(:customer, name: "Fulano de Tal")
        create(:customer, name: "Ciclano da Silva")

        get "/customers", params: { sort: "name", direction: "asc" }

        expect(response.parsed_body["content"].map { |c| c["name"] }).to eq([ "Ciclano da Silva", "Fulano de Tal" ])
      end

      it "sorts by name descending" do
        create(:customer, name: "Fulano de Tal")
        create(:customer, name: "Ciclano da Silva")

        get "/customers", params: { sort: "name", direction: "desc" }

        expect(response.parsed_body["content"].map { |c| c["name"] }).to eq([ "Fulano de Tal", "Ciclano da Silva" ])
      end

      it "ignores an unsupported sort column" do
        create(:customer, name: "Fulano de Tal")
        create(:customer, name: "Ciclano da Silva")

        get "/customers", params: { sort: "document", direction: "asc" }

        expect(response).to have_http_status(:ok)
      end

      it "defaults to active customers when active is omitted" do
        create(:customer, name: "Fulano de Tal")

        get "/customers"

        expect(response.parsed_body["content"].map { |c| c["name"] }).to eq([ "Fulano de Tal" ])
      end

      it "excludes soft deleted customers when active is true" do
        post "/customers", params: valid_params
        id = response.parsed_body["id"]
        delete "/customers/#{id}"

        get "/customers", params: { active: "true" }

        expect(response.parsed_body["content"]).to eq([])
      end

      it "returns only soft deleted customers when active is false" do
        create(:customer, name: "Fulano de Tal")
        post "/customers", params: valid_params.deep_merge(customer: { name: "Ciclano da Silva" })
        id = response.parsed_body["id"]
        delete "/customers/#{id}"

        get "/customers", params: { active: "false" }

        expect(response.parsed_body["content"].map { |c| c["name"] }).to eq([ "Ciclano da Silva" ])
      end

      it "returns both active and soft deleted customers when active is all" do
        create(:customer, name: "Fulano de Tal")
        post "/customers", params: valid_params.deep_merge(customer: { name: "Ciclano da Silva" })
        id = response.parsed_body["id"]
        delete "/customers/#{id}"

        get "/customers", params: { active: "all" }

        expect(response.parsed_body["content"].map { |c| c["name"] }).to contain_exactly("Fulano de Tal", "Ciclano da Silva")
      end
    end
  end
end
