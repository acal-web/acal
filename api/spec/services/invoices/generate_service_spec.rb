require "rails_helper"

RSpec.describe Invoices::GenerateService do
  let(:category) { create(:category, water_price: 15, membership_price: 5) }
  let(:connection_a) { create(:connection, customer: create(:customer), address: create(:address), category: category) }
  let(:connection_b) { create(:connection, customer: create(:customer), address: create(:address), category: category) }

  it "creates one invoice per connection, with the amount computed from the category" do
    invoices = described_class.call(
      connection_ids: [ connection_a.id, connection_b.id ],
      reference_date: "2026-08-01",
      due_date: "2026-08-10"
    )

    expect(invoices.map(&:connection_id)).to contain_exactly(connection_a.id, connection_b.id)
    expect(invoices).to all(have_attributes(reference_date: Date.new(2026, 8, 1), due_date: Date.new(2026, 8, 10), amount: 20.0))
  end

  it "rolls back the whole batch if one of the connections already has an invoice for that reference month" do
    create(:invoice, connection: connection_a, reference_date: "2026-08-01")

    expect {
      described_class.call(
        connection_ids: [ connection_a.id, connection_b.id ],
        reference_date: "2026-08-01",
        due_date: "2026-08-10"
      )
    }.to raise_error(ActiveRecord::RecordNotUnique)

    expect(Invoice.where(connection: connection_b)).to be_empty
  end

  it "creates a WaterMeter and charges for excess consumption when readings are given" do
    invoices = described_class.call(
      connection_ids: [ connection_a.id ],
      reference_date: "2026-08-01",
      due_date: "2026-08-10",
      water_meters: [
        { "connection_id" => connection_a.id, "initial_reading" => 1000, "final_reading" => 12000 }
      ]
    )

    invoice = invoices.first
    expect(invoice.water_consumed_value).to eq(4.0) # (11000 - 10000 free tier) / 1000 * 4
    water_meter = WaterMeter.find_by(invoice: invoice)
    expect(water_meter).to be_present
    expect(water_meter.initial_reading).to eq(1000)
    expect(water_meter.final_reading).to eq(12000)
    expect(water_meter.measured_at).to eq(Date.new(2026, 8, 1))
  end

  it "notifies the customer for each connection once its invoice is created" do
    allow(Notifications::NewInvoiceNotifier).to receive(:call)

    invoices = described_class.call(
      connection_ids: [ connection_a.id, connection_b.id ],
      reference_date: "2026-08-01",
      due_date: "2026-08-10"
    )

    invoice_a = invoices.find { |invoice| invoice.connection_id == connection_a.id }
    invoice_b = invoices.find { |invoice| invoice.connection_id == connection_b.id }

    expect(Notifications::NewInvoiceNotifier).to have_received(:call).with(connection: connection_a, invoice: invoice_a)
    expect(Notifications::NewInvoiceNotifier).to have_received(:call).with(connection: connection_b, invoice: invoice_b)
  end
end
