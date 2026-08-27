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

    it "excludes paid invoices, including overdue ones already paid" do
      paid_invoice = create(:invoice, :paid, connection: connection, reference_date: 2.months.ago.beginning_of_month)

      get "/portal/invoices"

      ids = response.parsed_body["content"].map { |i| i["id"] }
      expect(ids).to contain_exactly(my_invoice.id)
      expect(ids).not_to include(paid_invoice.id)
    end

    it "includes overdue unpaid invoices, not just upcoming ones" do
      overdue_invoice = create(:invoice, connection: connection, due_date: 10.days.ago, reference_date: 2.months.ago.beginning_of_month)

      get "/portal/invoices"

      ids = response.parsed_body["content"].map { |i| i["id"] }
      expect(ids).to include(overdue_invoice.id)
    end

    it "orders invoices from oldest due date to most recent" do
      oldest = create(:invoice, connection: connection, due_date: 3.months.ago, reference_date: 3.months.ago.beginning_of_month)
      middle = create(:invoice, connection: connection, due_date: 2.months.ago, reference_date: 2.months.ago.beginning_of_month)
      newest = create(:invoice, connection: connection, due_date: 1.month.from_now, reference_date: 1.month.from_now.beginning_of_month)

      get "/portal/invoices"

      ids = response.parsed_body["content"].map { |i| i["id"] }
      expect(ids.index(oldest.id)).to be < ids.index(middle.id)
      expect(ids.index(middle.id)).to be < ids.index(newest.id)
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
