require "rails_helper"

RSpec.describe Invoices::OverdueConnectionsService do
  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category, water_price: 15, membership_price: 5) }
  let(:connection) { create(:connection, customer: customer, address: address, category: category) }

  it "groups unpaid invoices overdue by more than the given threshold by connection" do
    invoice = create(:invoice, connection: connection, reference_date: "2026-06-01", due_date: Date.current - 45.days, membership_value: 15.0, water_value: 5.0)

    result = described_class.call(days: 30)

    expect(result).to contain_exactly(
      connection_id: connection.id,
      connection_number: "#{connection.number}#{connection.letter}",
      customer: { id: customer.id, name: customer.name },
      address: { id: address.id, name: address.name },
      category: { id: category.id, name: category.name },
      invoices: [ { id: invoice.id, reference_date: invoice.reference_date, due_date: invoice.due_date, membership_value: invoice.membership_value, water_value: invoice.water_value } ],
      total_amount: 20.0,
      days_overdue: 45,
      subject_to_cutoff: false
    )
  end

  it "sums multiple overdue invoices for the same connection" do
    create(:invoice, connection: connection, reference_date: "2026-05-01", due_date: Date.current - 60.days, membership_value: 15.0, water_value: 5.0)
    create(:invoice, connection: connection, reference_date: "2026-06-01", due_date: Date.current - 45.days, membership_value: 15.0, water_value: 5.0)

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

  describe "the cutoff warning" do
    it "is off at exactly the threshold" do
      create(:invoice, connection: connection, due_date: Date.current - described_class::CUTOFF_DAYS.days)

      group = described_class.call(days: 30).first

      expect(group[:days_overdue]).to eq(described_class::CUTOFF_DAYS)
      expect(group[:subject_to_cutoff]).to be(false)
    end

    it "is on past the threshold" do
      create(:invoice, connection: connection, due_date: Date.current - (described_class::CUTOFF_DAYS + 1).days)

      group = described_class.call(days: 30).first

      expect(group[:days_overdue]).to eq(described_class::CUTOFF_DAYS + 1)
      expect(group[:subject_to_cutoff]).to be(true)
    end

    it "is driven by the oldest invoice, not the newest" do
      create(:invoice, connection: connection, reference_date: "2026-01-01", due_date: Date.current - 200.days)
      create(:invoice, connection: connection, reference_date: "2026-06-01", due_date: Date.current - 35.days)

      group = described_class.call(days: 30).first

      expect(group[:days_overdue]).to eq(200)
      expect(group[:subject_to_cutoff]).to be(true)
    end
  end

  describe "filtering by address" do
    let(:other_address) { create(:address) }
    let(:other_connection) { create(:connection, customer: create(:customer), address: other_address, category: category) }

    before do
      create(:invoice, connection: connection, due_date: Date.current - 45.days, membership_value: 15.0, water_value: 5.0)
      create(:invoice, connection: other_connection, due_date: Date.current - 45.days, membership_value: 15.0, water_value: 5.0)
    end

    it "keeps only the connections on the given address" do
      result = described_class.call(days: 30, address_id: address.id)

      expect(result.map { |group| group[:connection_id] }).to eq([ connection.id ])
    end

    it "narrows connections_scope to that address" do
      expect(described_class.connections_scope(days: 30, address_id: address.id).map(&:id)).to eq([ connection.id ])
    end

    it "totals only that address" do
      expect(described_class.total_amount(days: 30, address_id: address.id)).to eq(20.0)
      expect(described_class.total_amount(days: 30)).to eq(40.0)
    end
  end

  describe ".connections_scope" do
    it "includes soft-deleted connections that still owe" do
      create(:invoice, connection: connection, due_date: Date.current - 45.days)
      connection.soft_delete!

      expect(described_class.connections_scope(days: 30).map(&:id)).to eq([ connection.id ])
    end

    it "excludes connections without overdue invoices" do
      create(:invoice, connection: connection, due_date: Date.current + 10.days)

      expect(described_class.connections_scope(days: 30)).to be_empty
    end
  end

  describe "restricting to one page of connections" do
    let(:other_connection) { create(:connection, customer: create(:customer), address: create(:address), category: category) }

    before do
      create(:invoice, connection: connection, due_date: Date.current - 45.days)
      create(:invoice, connection: other_connection, due_date: Date.current - 45.days)
    end

    it "returns only the given connections" do
      result = described_class.call(days: 30, connections: [ other_connection ])

      expect(result.map { |group| group[:connection_id] }).to eq([ other_connection.id ])
    end

    it "returns the groups in the order the connections came in" do
      result = described_class.call(days: 30, connections: [ other_connection, connection ])

      expect(result.map { |group| group[:connection_id] }).to eq([ other_connection.id, connection.id ])
    end
  end
end
