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
    end
  end

  describe "GET /customers/:id" do
    context "when successful" do
      it "returns the customer" do
        post "/customers", params: valid_params
        id = response.parsed_body["id"]

        get "/customers/#{id}"

        customer = Customer.find(id)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "id" => customer.id,
          "name" => "Fulano de Tal",
          "document" => valid_document,
          "membership_number" => 42,
          "voter" => true,
          "legacy_id" => nil,
          "created_at" => customer.created_at.as_json,
          "updated_at" => customer.updated_at.as_json,
          "deleted_at" => nil
        )
      end
    end

    context "when it fails" do
      it "returns not found for a nonexistent customer" do
        get "/customers/00000000-0000-0000-0000-000000000000"

        expect(response).to have_http_status(:not_found)
      end

      it "returns not found for a soft deleted customer" do
        post "/customers", params: valid_params
        id = response.parsed_body["id"]
        delete "/customers/#{id}"

        get "/customers/#{id}"

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /customers" do
    context "when successful" do
      it "creates a customer" do
        expect {
          post "/customers", params: valid_params
        }.to change(Customer, :count).by(1)

        customer = Customer.last

        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to eq(
          "id" => customer.id,
          "name" => "Fulano de Tal",
          "document" => valid_document,
          "membership_number" => 42,
          "voter" => true,
          "legacy_id" => nil,
          "created_at" => customer.created_at.as_json,
          "updated_at" => customer.updated_at.as_json,
          "deleted_at" => nil
        )
      end

      it "accepts a CNPJ (14 digits) as the document" do
        cnpj = DocumentGenerator.cnpj(123_456_780_001)

        post "/customers", params: { customer: valid_params[:customer].merge(document: cnpj) }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["document"]).to eq(cnpj)
      end

      it "strips punctuation from the document" do
        formatted = valid_document.sub(/\A(\d{3})(\d{3})(\d{3})(\d{2})\z/, '\1.\2.\3-\4')

        post "/customers", params: { customer: valid_params[:customer].merge(document: formatted) }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["document"]).to eq(valid_document)
      end

      it "accepts and returns a legacy_id" do
        post "/customers", params: { customer: valid_params[:customer].merge(legacy_id: 123) }

        customer = Customer.last

        expect(response).to have_http_status(:created)
        expect(customer.legacy_id).to eq(123)
        expect(response.parsed_body["legacy_id"]).to eq(123)
      end

      it "strips leading and trailing whitespace from the name" do
        post "/customers", params: { customer: valid_params[:customer].merge(name: "  Fulano de Tal  ") }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("Fulano de Tal")
      end

      it "defaults voter to false when omitted" do
        post "/customers", params: { customer: valid_params[:customer].except(:voter) }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["voter"]).to eq(false)
      end

      it "accepts a request without a membership number" do
        post "/customers", params: { customer: valid_params[:customer].except(:membership_number) }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["membership_number"]).to be_nil
      end
    end

    context "when it fails" do
      it "rejects a request without a name" do
        post "/customers", params: { customer: valid_params[:customer].except(:name) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("name" => [ "can't be blank", "is too short (minimum is 3 characters)" ])
      end

      it "rejects a request without a document" do
        post "/customers", params: { customer: valid_params[:customer].except(:document) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("document" => [ "can't be blank", "is invalid" ])
      end

      it "rejects a document that isn't a valid CPF or CNPJ length" do
        post "/customers", params: { customer: valid_params[:customer].merge(document: "123") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("document" => [ "is invalid" ])
      end

      it "rejects a CPF with an invalid check digit" do
        bad_document = valid_document[0...9] + "00"

        post "/customers", params: { customer: valid_params[:customer].merge(document: bad_document) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("document" => [ "is invalid" ])
      end

      it "rejects a CPF made of a single repeated digit" do
        post "/customers", params: { customer: valid_params[:customer].merge(document: "11111111111") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("document" => [ "is invalid" ])
      end

      it "rejects a document that is already in use" do
        post "/customers", params: valid_params

        post "/customers", params: { customer: valid_params[:customer].merge(name: "Outro Nome") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("document" => [ "has already been taken" ])
      end

      it "rejects a document already used by a soft deleted customer" do
        post "/customers", params: valid_params
        id = response.parsed_body["id"]
        delete "/customers/#{id}"

        post "/customers", params: { customer: valid_params[:customer].merge(name: "Outro Nome") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("document" => [ "has already been taken" ])
      end

      it "rejects a membership number that isn't a positive integer" do
        post "/customers", params: { customer: valid_params[:customer].merge(membership_number: 0) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("membership_number" => [ "must be greater than 0" ])
      end
    end
  end

  describe "PATCH /customers/:id" do
    context "when successful" do
      it "updates the customer" do
        post "/customers", params: valid_params
        id = response.parsed_body["id"]

        patch "/customers/#{id}", params: {
          customer: { name: "Ciclano", document: "98765432100", membership_number: 7, voter: false }
        }

        customer = Customer.find(id)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "id" => customer.id,
          "name" => "Ciclano",
          "document" => "98765432100",
          "membership_number" => 7,
          "voter" => false,
          "legacy_id" => nil,
          "created_at" => customer.created_at.as_json,
          "updated_at" => customer.updated_at.as_json,
          "deleted_at" => nil
        )
      end
    end

    context "when it fails" do
      it "rejects a request without a name" do
        post "/customers", params: valid_params
        id = response.parsed_body["id"]

        patch "/customers/#{id}", params: { customer: valid_params[:customer].except(:name) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("name" => [ "can't be blank", "is too short (minimum is 3 characters)" ])
      end
    end
  end

  describe "DELETE /customers/:id" do
    context "when successful" do
      it "soft deletes the customer instead of removing it" do
        post "/customers", params: valid_params
        customer = Customer.last

        expect {
          delete "/customers/#{customer.id}"
        }.not_to change(Customer.unscoped, :count)

        expect(response).to have_http_status(:no_content)
        expect(customer.reload.deleted_at).not_to be_nil
      end

      it "excludes the customer from the default scope" do
        post "/customers", params: valid_params
        customer = Customer.last

        delete "/customers/#{customer.id}"

        expect(Customer.exists?(customer.id)).to be(false)
      end
    end
  end
end
