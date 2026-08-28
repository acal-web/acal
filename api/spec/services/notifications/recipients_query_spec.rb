require "rails_helper"

RSpec.describe Notifications::RecipientsQuery do
  let(:address) { create(:address) }
  let(:category) { create(:category) }

  it "returns customers with an active connection when no filter is given" do
    customer = create(:customer)
    create(:connection, customer: customer, address: address, category: category)

    expect(described_class.call).to contain_exactly(customer)
  end

  it "filters by address_id" do
    match = create(:customer)
    create(:connection, customer: match, address: address, category: category)

    other_address = create(:address)
    other_customer = create(:customer)
    create(:connection, customer: other_customer, address: other_address, category: category)

    expect(described_class.call(address_id: address.id)).to contain_exactly(match)
  end

  it "filters by category_id" do
    match = create(:customer)
    create(:connection, customer: match, address: address, category: category)

    other_category = create(:category)
    other_customer = create(:customer)
    create(:connection, customer: other_customer, address: create(:address), category: other_category)

    expect(described_class.call(category_id: category.id)).to contain_exactly(match)
  end

  it "combines address_id and category_id filters" do
    match = create(:customer)
    create(:connection, customer: match, address: address, category: category)

    non_match = create(:customer)
    create(:connection, customer: non_match, address: address, category: create(:category))

    expect(described_class.call(address_id: address.id, category_id: category.id)).to contain_exactly(match)
  end

  it "filters by status, excluding inactive connections by default filter value" do
    active_customer = create(:customer)
    create(:connection, customer: active_customer, address: address, category: category, active: true)

    inactive_customer = create(:customer)
    create(:connection, customer: inactive_customer, address: address, category: category, active: false)

    expect(described_class.call(status: "active")).to contain_exactly(active_customer)
    expect(described_class.call(status: "inactive")).to contain_exactly(inactive_customer)
  end

  it "does not duplicate a customer with multiple matching connections" do
    customer = create(:customer)
    create(:connection, customer: customer, address: address, category: category, number: 1)
    create(:connection, customer: customer, address: address, category: category, number: 2, active: false)

    expect(described_class.call(address_id: address.id).count).to eq(1)
  end
end
