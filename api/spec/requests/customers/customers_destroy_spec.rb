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

      it "deactivates the linked user's login along with the customer" do
        post "/customers", params: valid_params
        customer = Customer.last
        document = customer.document
        customer_code = customer.customer_code

        delete "/customers/#{customer.id}"

        post "/session", params: { session: { username: document, password: customer_code } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
