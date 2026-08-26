require "rails_helper"

RSpec.describe "Portal::Invoices", type: :request do
  let(:customer) { create(:customer) }
  let(:other_customer) { create(:customer) }
  let(:connection) { create(:connection_with_all_data, customer: customer) }
  let(:other_connection) { create(:connection_with_all_data, customer: other_customer) }
  let!(:my_invoice) { create(:invoice, connection: connection) }
  let!(:other_invoice) { create(:invoice, connection: other_connection) }

  before { sign_in_as_customer(customer) }

  describe "GET /portal/invoices" do
    it "only returns the authenticated customer's invoices" do
      get "/portal/invoices"

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["content"].map { |i| i["id"] }
      expect(ids).to contain_exactly(my_invoice.id)
    end
  end

  describe "GET /portal/invoices/:id" do
    it "returns the invoice when it belongs to the customer" do
      get "/portal/invoices/#{my_invoice.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(my_invoice.id)
    end

    it "returns 404 for another customer's invoice" do
      get "/portal/invoices/#{other_invoice.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /portal/invoices/:id/pdf" do
    it "returns 404 for another customer's invoice" do
      get "/portal/invoices/#{other_invoice.id}/pdf"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "without a customer token", :skip_auth do
    it "returns 401" do
      get "/portal/invoices"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
