require "rails_helper"

RSpec.describe Invoices::OverdueConnectionsService do
  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category, water_price: 15, membership_price: 5) }
  let(:connection) { create(:connection, customer: customer, address: address, category: category) }

  it "groups unpaid invoices overdue by more than the given threshold by connection" do
    invoice = create(:invoice, connection: connection, reference_date: "2026-06-01", due_date: Date.current - 45.days, amount: 20.0)

    result = described_class.call(days: 30)

    expect(result).to contain_exactly(
      connection_id: connection.id,
      connection_number: "#{connection.number}#{connection.letter}",
      customer: { id: customer.id, name: customer.name },
      address: { id: address.id, name: address.name },
      category: { id: category.id, name: category.name },
      invoices: [ { id: invoice.id, reference_date: invoice.reference_date, due_date: invoice.due_date, membership_value: invoice.membership_value, water_value: invoice.water_value } ],
      total_amount: 20.0
    )
  end

  it "sums multiple overdue invoices for the same connection" do
    create(:invoice, connection: connection, reference_date: "2026-05-01", due_date: Date.current - 60.days, amount: 20.0)
    create(:invoice, connection: connection, reference_date: "2026-06-01", due_date: Date.current - 45.days, amount: 20.0)

    result = described_class.call(days: 30)

    expect(result.length).to eq(1)
    expect(result.first[:invoices].length).to eq(2)
    expect(result.first[:total_amount]).to eq(40.0)
  end

  it "excludes invoices not yet overdue by the threshold" do
    create(:invoice, connection: connection, due_date: Date.current - 10.days)

    expect(described_class.call(days: 30)).to eq([])
  end

  it "excludes invoices that have been paid" do
    create(:invoice, :paid, connection: connection, due_date: Date.current - 45.days)

    expect(described_class.call(days: 30)).to eq([])
  end
end
