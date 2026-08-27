require "rails_helper"

RSpec.describe Reports::DunningReport do
  let(:group) do
    {
      connection_id: SecureRandom.uuid,
      connection_number: "42A",
      customer: { id: SecureRandom.uuid, name: "Fulano de Tal" },
      address: { id: SecureRandom.uuid, name: "Rua das Flores" },
      category: { id: SecureRandom.uuid, name: "Efetivo" },
      invoices: [
        { id: SecureRandom.uuid, reference_date: Date.new(2026, 7, 1), due_date: Date.new(2026, 7, 10), membership_value: 5, water_value: 15 },
        { id: SecureRandom.uuid, reference_date: Date.new(2026, 8, 1), due_date: Date.new(2026, 8, 10), membership_value: 5, water_value: 15 }
      ],
      total_amount: 40
    }
  end

  subject(:report) { described_class.new(group) }

  it "exposes the customer name" do
    expect(report.customer_name).to eq("Fulano de Tal")
  end

  it "formats the connection's location as address + number" do
    expect(report.connection_location).to eq("Rua das Flores, nº 42A")
  end

  it "formats each invoice as a [reference, due date, amount] row" do
    expect(report.invoice_rows).to eq([
      [ "07/2026", "10/07/2026", Reports::PdfFactory.currency(20.0) ],
      [ "08/2026", "10/08/2026", Reports::PdfFactory.currency(20.0) ]
    ])
  end

  it "formats the total amount" do
    expect(report.total_label).to eq(Reports::PdfFactory.currency(40))
  end
end
