require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /dashboard/summary" do
    it "returns 403 for a role without dashboard:read" do
      sign_in_as_customer(create(:customer))

      get "/dashboard/summary"

      expect(response).to have_http_status(:forbidden)
    end

    it "sums paid invoices within the given month as total_received" do
      create(:invoice, connection: create(:connection_with_all_data), membership_value: 10, water_value: 5,
        reference_date: "2026-08-01", paid_at: "2026-08-05")
      create(:invoice, connection: create(:connection_with_all_data), membership_value: 20, water_value: 0,
        reference_date: "2026-08-01", paid_at: "2026-08-06")
      # Paid outside the requested month — must not count.
      create(:invoice, connection: create(:connection_with_all_data), membership_value: 100, water_value: 0,
        reference_date: "2026-07-01", paid_at: "2026-07-05")

      get "/dashboard/summary", params: { year: 2026, month: 8 }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["total_received"]).to eq(35.0)
      expect(body["invoices_received_count"]).to eq(2)
    end

    it "sums unpaid invoices (any period) as total_receivable" do
      create(:invoice, connection: create(:connection_with_all_data), membership_value: 10, water_value: 5, paid_at: nil)
      create(:invoice, connection: create(:connection_with_all_data), membership_value: 15, water_value: 0, paid_at: nil)
      create(:invoice, connection: create(:connection_with_all_data), membership_value: 999, water_value: 0, paid_at: Time.current)

      get "/dashboard/summary", params: { year: 2026, month: 8 }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["total_receivable"]).to eq(30.0)
      expect(body["invoices_receivable_count"]).to eq(2)
    end

    it "counts invoices paid today, separately from the month total" do
      create(:invoice, connection: create(:connection_with_all_data), membership_value: 50, water_value: 0, paid_at: Time.current)
      create(:invoice, connection: create(:connection_with_all_data), membership_value: 999, water_value: 0,
        reference_date: 3.months.ago, paid_at: 3.days.ago)

      get "/dashboard/summary", params: { year: Date.current.year, month: Date.current.month }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["total_received_today"]).to eq(50.0)
      expect(body["invoices_paid_today_count"]).to eq(1)
    end

    it "lists up to 10 recent invoices for the period with their connection included" do
      12.times { create(:invoice, connection: create(:connection_with_all_data), reference_date: "2026-08-01") }

      get "/dashboard/summary", params: { year: 2026, month: 8 }

      body = response.parsed_body
      expect(body["recent_invoices"].size).to eq(10)
      expect(body["recent_invoices"].first["connection"]["customer"]).to be_present
    end

    it "counts active connections grouped by category group" do
      create(:connection_with_all_data, category: create(:category, group: "efetivo"))
      create(:connection_with_all_data, category: create(:category, group: "efetivo"))
      create(:connection_with_all_data, category: create(:category, group: "fundador"))
      create(:connection_with_all_data, active: false, category: create(:category, group: "temporario"))

      get "/dashboard/summary", params: { year: 2026, month: 8 }

      counts = response.parsed_body["members_by_category"].index_by { |c| c["group"] }
      expect(counts["efetivo"]["count"]).to eq(2)
      expect(counts["fundador"]["count"]).to eq(1)
      expect(counts["temporario"]["count"]).to eq(0)
    end

    it "defaults year/month to the current month when not given" do
      create(:invoice, connection: create(:connection_with_all_data), membership_value: 40, water_value: 0,
        reference_date: Date.current.beginning_of_month, paid_at: Date.current)

      get "/dashboard/summary"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["total_received"]).to eq(40.0)
    end
  end
end
