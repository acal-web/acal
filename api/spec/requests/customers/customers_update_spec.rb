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
          "tags" => [],
          "customer_code" => customer.customer_code,
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
end
