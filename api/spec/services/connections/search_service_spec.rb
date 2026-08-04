require "rails_helper"

RSpec.describe Connections::SearchService do
  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category) }

  it "returns all connections, with customer/address/category preloaded, when no filter is given" do
    connection = create(:connection, customer: customer, address: address, category: category)

    result = described_class.call

    expect(result).to contain_exactly(connection)
    expect(result.first.association(:customer)).to be_loaded
    expect(result.first.association(:address)).to be_loaded
    expect(result.first.association(:category)).to be_loaded
  end

  it "combines the customer_name and address_name filters" do
    match = create(:connection, customer: customer, address: address, category: category)
    create(:connection, customer: create(:customer), address: create(:address, name: "Second Avenue"), category: category)

    result = described_class.call(customer_name: customer.name[0, 6], address_name: address.name[0, 4])

    expect(result).to contain_exactly(match)
  end

  it "filters by category_id, excluding connections whose category was soft deleted" do
    match = create(:connection, customer: customer, address: address, category: category)
    deleted_category = create(:category, name: "Especial")
    create(:connection, customer: create(:customer), address: create(:address), category: deleted_category)
    deleted_category.soft_delete!

    expect(described_class.call(category_id: category.id)).to contain_exactly(match)
    expect(described_class.call(category_id: deleted_category.id)).to eq([])
  end

  it "filters by active status" do
    active_connection = create(:connection, customer: customer, address: address, category: category, active: true)
    create(:connection, customer: create(:customer), address: create(:address), category: category, active: false)

    expect(described_class.call(active: false)).not_to include(active_connection)
    expect(described_class.call(active: true)).to contain_exactly(active_connection)
  end
end
