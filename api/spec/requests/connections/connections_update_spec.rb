require "rails_helper"

RSpec.describe "Connections", type: :request do
  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category) }
  let(:valid_params) do
    { connection: { customer_id: customer.id, address_id: address.id, category_id: category.id, number: 1 } }
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

      it "rejects moving an active connection onto a number another active connection already holds, with no letter on either" do
        post "/connections", params: valid_params

        other_customer = create(:customer, name: "Ciclano")
        post "/connections", params: { connection: { customer_id: other_customer.id, address_id: address.id, category_id: category.id, number: 2 } }
        other_id = response.parsed_body["id"]

        patch "/connections/#{other_id}", params: { connection: { customer_id: other_customer.id, address_id: address.id, category_id: category.id, number: 1 } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("address_id" => [ "already has an active connection for this address number" ])
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
end
