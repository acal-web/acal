require "rails_helper"

RSpec.describe Connections::CreateService do
  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category) }

  it "creates a connection, defaulting active to true" do
    connection = described_class.call(customer_id: customer.id, address_id: address.id, category_id: category.id)

    expect(connection).to be_persisted
    expect(connection.customer_id).to eq(customer.id)
    expect(connection.address_id).to eq(address.id)
    expect(connection.category_id).to eq(category.id)
    expect(connection.active).to be(true)
  end

  it "accepts an explicit active flag and a legacy_id" do
    connection = described_class.call(
      customer_id: customer.id,
      address_id: address.id,
      category_id: category.id,
      active: false,
      legacy_id: 123
    )

    expect(connection.active).to be(false)
    expect(connection.legacy_id).to eq(123)
  end

  it "raises when the address already has an active connection" do
    create(:connection, customer: customer, address: address, category: category)
    other_customer = create(:customer)

    expect {
      described_class.call(customer_id: other_customer.id, address_id: address.id, category_id: category.id)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "allows any number of inactive connections on the same address" do
    create(:connection, customer: customer, address: address, category: category, active: false)

    expect {
      3.times { described_class.call(customer_id: create(:customer).id, address_id: address.id, category_id: category.id, active: false) }
    }.to change(Connection, :count).by(3)
  end

  it "raises when the customer already has an active efetivo connection" do
    create(:connection, customer: customer, address: address, category: category)
    other_address = create(:address)

    expect {
      described_class.call(customer_id: customer.id, address_id: other_address.id, category_id: category.id)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "allows the customer to have another active connection outside the efetivo group" do
    create(:connection, customer: customer, address: address, category: category)
    other_address = create(:address)
    temporario_category = create(:category, group: "temporario")

    connection = described_class.call(customer_id: customer.id, address_id: other_address.id, category_id: temporario_category.id)

    expect(connection).to be_persisted
  end
end
