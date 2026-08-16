require "rails_helper"

RSpec.describe Invoices::EligibleConnectionsService do
  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category, water_price: 15, membership_price: 5) }

  it "returns active connections without an invoice for the reference, with the amount computed from the category" do
    connection = create(:connection, customer: customer, address: address, category: category)

    result = described_class.call(reference_date: "2026-08-01")

    expect(result).to contain_exactly(
      connection_id: connection.id,
      customer: { id: customer.id, name: customer.name },
      address: { id: address.id, name: address.name },
      number: connection.number,
      letter: connection.letter,
      category: { id: category.id, name: category.name, has_water_meter: category.has_water_meter },
      membership_value: 5.0,
      water_value: 15.0
    )
  end

  it "excludes inactive connections" do
    create(:connection, customer: customer, address: address, category: category, active: false)

    expect(described_class.call(reference_date: "2026-08-01")).to eq([])
  end

  it "excludes connections that already have an invoice for that reference month, but keeps them for other months" do
    connection = create(:connection, customer: customer, address: address, category: category)
    create(:invoice, connection: connection, reference_date: "2026-08-01")

    expect(described_class.call(reference_date: "2026-08-01")).to eq([])
    expect(described_class.call(reference_date: "2026-09-01").map { |c| c[:connection_id] }).to contain_exactly(connection.id)
  end

  it "does not exclude a connection whose invoice for that month was soft deleted" do
    connection = create(:connection, customer: customer, address: address, category: category)
    invoice = create(:invoice, connection: connection, reference_date: "2026-08-01")
    invoice.soft_delete!

    expect(described_class.call(reference_date: "2026-08-01").map { |c| c[:connection_id] }).to contain_exactly(connection.id)
  end

  it "filters by address_id" do
    match = create(:connection, customer: customer, address: address, category: category)
    create(:connection, customer: create(:customer), address: create(:address), category: category)

    result = described_class.call(reference_date: "2026-08-01", address_id: address.id)

    expect(result.map { |c| c[:connection_id] }).to contain_exactly(match.id)
  end

  it "filters by has_water_meter" do
    with_meter = create(:category, water_price: 15, membership_price: 5, has_water_meter: true)
    without_meter = create(:category, water_price: 15, membership_price: 5, has_water_meter: false)
    match = create(:connection, customer: customer, address: address, category: with_meter)
    create(:connection, customer: create(:customer), address: create(:address), category: without_meter)

    result = described_class.call(reference_date: "2026-08-01", has_water_meter: true)

    expect(result.map { |c| c[:connection_id] }).to contain_exactly(match.id)
  end
end
