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

  describe "PATCH /customers/:id/restore" do
    it "reactivates the linked user's login along with the customer" do
      post "/customers", params: valid_params
      customer = Customer.last
      document = customer.document
      customer_code = customer.customer_code
      delete "/customers/#{customer.id}"

      patch "/customers/#{customer.id}/restore"

      post "/session", params: { session: { username: document, password: customer_code } }
      expect(response).to have_http_status(:created)
    end
  end
end
