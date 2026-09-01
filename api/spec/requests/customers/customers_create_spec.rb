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
          "tags" => [],
          "customer_code" => customer.customer_code,
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

      it "rejects a document already used by an active customer, naming them" do
        post "/customers", params: valid_params

        post "/customers", params: { customer: valid_params[:customer].merge(name: "Outro Nome") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq(
          "document" => [ "Já existe um cadastro para esse documento associado ao usuário Fulano de Tal" ]
        )
      end

      it "rejects a document already used by a soft deleted customer, offering to reactivate" do
        post "/customers", params: valid_params
        id = response.parsed_body["id"]
        delete "/customers/#{id}"

        post "/customers", params: { customer: valid_params[:customer].merge(name: "Outro Nome") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq(
          "document" => [ "Esse sócio já está cadastrado, porém inativo. É possível reativar." ]
        )
      end

      it "rejects a membership number that isn't a positive integer" do
        post "/customers", params: { customer: valid_params[:customer].merge(membership_number: 0) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("membership_number" => [ "must be greater than 0" ])
      end
    end
  end
end
