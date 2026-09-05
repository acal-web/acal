require "rails_helper"

RSpec.describe "Invoices", type: :request do
  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category, water_price: 15, membership_price: 5) }
  let(:connection) { create(:connection, customer: customer, address: address, category: category) }

  describe "GET /invoices" do
    it "lists invoices with their connection, customer, address and category" do
      invoice = create(:invoice, connection: connection, reference_date: "2026-08-01")

      get "/invoices"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["content"].length).to eq(1)
      invoice_json = body["content"].first
      expect(invoice_json["id"]).to eq(invoice.id)
      expect(invoice_json["connection"]["id"]).to eq(connection.id)
      expect(invoice_json["connection"]["customer"]["id"]).to eq(customer.id)
      expect(invoice_json["connection"]["address"]["id"]).to eq(address.id)
      expect(invoice_json["connection"]["category"]["id"]).to eq(category.id)
    end

    it "orders by reference_date descending" do
      other_connection = create(:connection, customer: create(:customer), address: create(:address), category: category)
      older = create(:invoice, connection: connection, reference_date: "2026-06-01")
      newer = create(:invoice, connection: other_connection, reference_date: "2026-07-01")

      get "/invoices"

      ids = response.parsed_body["content"].map { |i| i["id"] }
      expect(ids).to eq([ newer.id, older.id ])
    end

    it "filters by status=unpaid" do
      unpaid = create(:invoice, connection: connection)
      create(:invoice, :paid, connection: connection, reference_date: "2026-07-01")

      get "/invoices", params: { status: "unpaid" }

      ids = response.parsed_body["content"].map { |i| i["id"] }
      expect(ids).to eq([ unpaid.id ])
    end

    it "filters by reference period" do
      other_connection = create(:connection, customer: create(:customer), address: create(:address), category: category)
      matching = create(:invoice, connection: connection, reference_date: "2026-08-01")
      create(:invoice, connection: other_connection, reference_date: "2026-07-01")

      get "/invoices", params: { year: 2026, month: 8 }

      ids = response.parsed_body["content"].map { |i| i["id"] }
      expect(ids).to eq([ matching.id ])
    end
  end

  describe "GET /invoices/:id" do
    it "returns a single invoice with its connection, customer, address and category" do
      invoice = create(:invoice, connection: connection, reference_date: "2026-08-01")

      get "/invoices/#{invoice.id}"

      expect(response).to have_http_status(:ok)
      invoice_json = response.parsed_body
      expect(invoice_json["id"]).to eq(invoice.id)
      expect(invoice_json["connection"]["id"]).to eq(connection.id)
      expect(invoice_json["connection"]["customer"]["id"]).to eq(customer.id)
      expect(invoice_json["connection"]["address"]["id"]).to eq(address.id)
      expect(invoice_json["connection"]["category"]["id"]).to eq(category.id)
    end

    it "returns 404 for a non-existent invoice" do
      get "/invoices/non-existent-id"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /invoices/eligible" do
    it "returns active connections without an invoice for the given reference" do
      connection

      get "/invoices/eligible", params: { reference_date: "2026-08-01" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        [
          {
            "connection_id" => connection.id,
            "customer" => { "id" => customer.id, "name" => customer.name },
            "address" => { "id" => address.id, "name" => address.name },
            "number" => connection.number,
            "letter" => connection.letter,
            "category" => { "id" => category.id, "name" => category.name, "has_water_meter" => category.has_water_meter },
            "membership_value" => "5.0",
            "water_value" => "15.0",
            "previous_meter_final_reading" => nil
          }
        ]
      )
    end

    it "excludes connections already invoiced for that reference" do
      create(:invoice, connection: connection, reference_date: "2026-08-01")

      get "/invoices/eligible", params: { reference_date: "2026-08-01" }

      expect(response.parsed_body).to eq([])
    end

    it "filters by address_id and has_water_meter" do
      connection

      get "/invoices/eligible", params: { reference_date: "2026-08-01", address_id: create(:address).id }
      expect(response.parsed_body).to eq([])

      get "/invoices/eligible", params: { reference_date: "2026-08-01", has_water_meter: true }
      expect(response.parsed_body).to eq([])
    end
  end

  describe "POST /invoices/generate" do
    context "when successful" do
      it "creates an invoice per connection" do
        expect {
          post "/invoices/generate", params: {
            connection_ids: [ connection.id ],
            reference_date: "2026-08-01",
            due_date: "2026-08-10"
          }
        }.to change(Invoice, :count).by(1)

        expect(response).to have_http_status(:created)
        invoice = Invoice.last
        expect(invoice.connection_id).to eq(connection.id)
        expect(invoice.reference_date).to eq(Date.new(2026, 8, 1))
        expect(invoice.due_date).to eq(Date.new(2026, 8, 10))
        expect(invoice.amount).to eq(20.0)
      end
    end

    context "when it fails" do
      it "rejects generating a duplicate invoice for the same connection and reference" do
        create(:invoice, connection: connection, reference_date: "2026-08-01")

        expect {
          post "/invoices/generate", params: {
            connection_ids: [ connection.id ],
            reference_date: "2026-08-01",
            due_date: "2026-08-10"
          }
        }.not_to change(Invoice, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Invoice already exists")
      end
    end
  end

  describe "GET /invoices/:id/pdf" do
    it "returns a PDF document for the invoice" do
      invoice = create(:invoice, connection: connection)

      get "/invoices/#{invoice.id}/pdf"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body).to start_with("%PDF")
    end

    it "returns a PDF document for an already-paid invoice" do
      invoice = create(:invoice, :paid, connection: connection)

      get "/invoices/#{invoice.id}/pdf"

      expect(response).to have_http_status(:ok)
      expect(response.body).to start_with("%PDF")
    end
  end

  describe "PATCH /invoices/:id/pay" do
    it "marks the invoice as paid" do
      invoice = create(:invoice, connection: connection)

      patch "/invoices/#{invoice.id}/pay"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(invoice.id)
      expect(invoice.reload.paid_at).to be_present
    end
  end

  describe "GET /invoices/overdue" do
    it "lists connections with overdue, unpaid invoices" do
      create(:invoice, connection: connection, due_date: Date.current - 45.days)

      get "/invoices/overdue"

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |group| group["connection_id"] }
      expect(ids).to contain_exactly(connection.id)
    end

    it "excludes connections without overdue invoices" do
      create(:invoice, connection: connection, due_date: Date.current + 10.days)

      get "/invoices/overdue"

      expect(response.parsed_body).to eq([])
    end
  end

  describe "GET /invoices/cashbox" do
    it "lists only paid invoices" do
      paid = create(:invoice, :paid, connection: connection, reference_date: "2026-08-01")
      create(:invoice, connection: connection, reference_date: "2026-07-01")

      get "/invoices/cashbox"

      ids = response.parsed_body["content"].map { |i| i["id"] }
      expect(ids).to eq([ paid.id ])
    end

    it "filters by paid_at within the given range" do
      matching = create(:invoice, connection: connection, reference_date: "2026-08-01", paid_at: Time.zone.parse("2026-08-15 10:00"))
      create(:invoice, connection: connection, reference_date: "2026-07-01", paid_at: Time.zone.parse("2026-07-31 23:59"))

      get "/invoices/cashbox", params: { start_date: "2026-08-01", end_date: "2026-08-31" }

      ids = response.parsed_body["content"].map { |i| i["id"] }
      expect(ids).to eq([ matching.id ])
    end

    it "returns the total amount of the filtered invoices, across all pages" do
      create(:invoice, :paid, connection: connection, membership_value: 15, water_value: 5)
      other_connection = create(:connection, customer: create(:customer), address: create(:address), category: category)
      create(:invoice, :paid, connection: other_connection, membership_value: 10, water_value: 2)

      get "/invoices/cashbox", params: { size: 1 }

      expect(response.parsed_body["content"].length).to eq(1)
      expect(response.parsed_body["totalAmount"].to_f).to eq(32.0)
    end
  end

  describe "GET /invoices/cobranca_pdf" do
    it "returns a PDF letter when there are overdue connections" do
      create(:invoice, connection: connection, due_date: Date.current - 45.days)

      get "/invoices/cobranca_pdf"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body).to start_with("%PDF")
    end

    it "returns no content when there is nothing overdue" do
      get "/invoices/cobranca_pdf"

      expect(response).to have_http_status(:no_content)
    end

    it "filters by connection_id" do
      other_connection = create(:connection, customer: create(:customer), address: create(:address), category: category)
      create(:invoice, connection: connection, due_date: Date.current - 45.days)

      get "/invoices/cobranca_pdf", params: { connection_id: other_connection.id }

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /invoices/print_filtered" do
    it "returns a PDF document for the filtered invoices" do
      create(:invoice, connection: connection, reference_date: "2026-08-01")

      get "/invoices/print_filtered", params: { year: 2026, month: 8 }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body).to start_with("%PDF")
    end

    it "returns no content when the filters match nothing" do
      get "/invoices/print_filtered", params: { year: 2020, month: 1 }

      expect(response).to have_http_status(:no_content)
    end

    it "includes that month's quality analyses in the report" do
      create(:invoice, connection: connection, reference_date: "2026-08-01")
      create(:quality_analysis, reference_date: "2026-08-15", param_name: "Turbidez")

      get "/invoices/print_filtered", params: { year: 2026, month: 8 }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/pdf")
    end
  end

  describe "GET /invoices sorting" do
    let(:other_connection) { create(:connection, customer: create(:customer, name: "Alice"), address: address, category: category) }

    it "sorts by number ascending" do
      first = create(:invoice, connection: connection, reference_date: "2026-08-01")
      second = create(:invoice, connection: other_connection, reference_date: "2026-07-01")
      lower, higher = [ first, second ].sort_by(&:number)

      get "/invoices", params: { sort_by: "number", sort_ascending: "true" }

      expect(response.parsed_body["content"].map { |i| i["id"] }).to eq([ lower.id, higher.id ])
    end

    it "sorts by reference_date explicitly" do
      earlier = create(:invoice, connection: connection, reference_date: "2026-06-01")
      later = create(:invoice, connection: other_connection, reference_date: "2026-07-01")

      get "/invoices", params: { sort_by: "reference_date", sort_ascending: "true" }

      expect(response.parsed_body["content"].map { |i| i["id"] }).to eq([ earlier.id, later.id ])
    end

    it "sorts by due_date" do
      earlier = create(:invoice, connection: connection, due_date: "2026-08-10")
      later = create(:invoice, connection: other_connection, due_date: "2026-08-20")

      get "/invoices", params: { sort_by: "due_date", sort_ascending: "true" }

      expect(response.parsed_body["content"].map { |i| i["id"] }).to eq([ earlier.id, later.id ])
    end

    it "sorts by amount" do
      cheaper = create(:invoice, connection: connection, membership_value: 5, water_value: 0)
      pricier = create(:invoice, connection: other_connection, membership_value: 50, water_value: 0)

      get "/invoices", params: { sort_by: "amount", sort_ascending: "true" }

      expect(response.parsed_body["content"].map { |i| i["id"] }).to eq([ cheaper.id, pricier.id ])
    end

    it "sorts by customer_name" do
      other_connection # Alice
      z_connection = create(:connection, customer: create(:customer, name: "Zeca"), address: address, category: category)
      alice_invoice = create(:invoice, connection: other_connection)
      zeca_invoice = create(:invoice, connection: z_connection)

      get "/invoices", params: { sort_by: "customer_name", sort_ascending: "true" }

      expect(response.parsed_body["content"].map { |i| i["id"] }).to eq([ alice_invoice.id, zeca_invoice.id ])
    end
  end
end
