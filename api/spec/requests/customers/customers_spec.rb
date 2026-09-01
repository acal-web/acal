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
          "tags" => [],
          "customer_code" => customer.customer_code,
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
end
