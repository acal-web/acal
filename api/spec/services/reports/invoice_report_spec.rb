require "rails_helper"

RSpec.describe Reports::InvoiceReport do
  let(:category) { create(:category, water_price: 15, membership_price: 5, name: "Efetivo") }
  let(:customer) { create(:customer, name: "Fulano de Tal") }
  let(:address) { create(:address, name: "Rua das Flores") }
  let(:connection) { create(:connection, customer: customer, address: address, category: category, number: 42) }
  let(:invoice) do
    create(:invoice,
      connection: connection,
      membership_value: 5,
      water_value: 15,
      reference_date: Date.new(2026, 8, 1),
      due_date: Date.new(2026, 8, 10))
  end

  subject(:report) { described_class.new(invoice) }

  it "exposes the customer/address/category from the connection" do
    expect(report.customer_name).to eq("Fulano de Tal")
    expect(report.address).to eq(connection.full_location)
    expect(report.category_name).to eq("Efetivo")
  end

  it "formats dates and money for display" do
    expect(report.reference_label).to eq("agosto, 2026")
    expect(report.issued_at_label).to eq("01 ago. 2026")
    expect(report.due_date_label).to eq("10 ago. 2026")
    expect(report.total_value_label).to eq(Reports::PdfFactory.currency(20.0))
  end

  it "reports unpaid invoices as such, with no paid-at label" do
    expect(report.paid?).to eq(false)
    expect(report.paid_at_label).to be_nil
  end

  it "reports paid invoices with a formatted paid-at label" do
    invoice.update!(paid_at: Time.zone.local(2026, 8, 15))

    expect(report.paid?).to eq(true)
    expect(report.paid_at_label).to eq("15 ago. 2026")
  end

  it "returns placeholder meter readings when there's no water meter" do
    expect(report.meter_readings).to eq([ "—", "—", "—" ])
  end

  it "formats meter readings with thousands separators when a meter exists" do
    create(:water_meter, invoice: invoice, initial_reading: 1000, final_reading: 2500)

    expect(report.meter_readings).to eq([ "1.000 L", "2.500 L", "1.500 L" ])
  end

  it "falls back to quality_analyses from the invoice when none are preloaded" do
    expect(report.quality_analyses).to eq(invoice.quality_analyses.to_a)
  end

  it "uses the preloaded quality_analyses when given" do
    preloaded = [ double("QualityAnalysis") ]
    report = described_class.new(invoice, quality_analyses: preloaded)

    expect(report.quality_analyses).to eq(preloaded)
  end
end
