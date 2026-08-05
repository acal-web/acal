require "rails_helper"

RSpec.describe Connections::CreateService do
  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category) }

  it "creates a connection, defaulting active to true" do
    connection = described_class.call(customer_id: customer.id, address_id: address.id, category_id: category.id, number: 1)

    expect(connection).to be_persisted
    expect(connection.customer_id).to eq(customer.id)
    expect(connection.address_id).to eq(address.id)
    expect(connection.category_id).to eq(category.id)
    expect(connection.number).to eq(1)
    expect(connection.letter).to be_nil
    expect(connection.active).to be(true)
    expect(connection.membership_date).to be_nil
    expect(connection.exclusively_member).to be(false)
  end

  it "accepts an explicit active flag, a legacy_id, a letter, a membership_date and exclusively_member" do
    connection = described_class.call(
      customer_id: customer.id,
      address_id: address.id,
      category_id: category.id,
      number: 1,
      letter: "A",
      active: false,
      legacy_id: 123,
      membership_date: Date.new(2024, 3, 15),
      exclusively_member: true
    )

    expect(connection.letter).to eq("A")
    expect(connection.active).to be(false)
    expect(connection.legacy_id).to eq(123)
    expect(connection.membership_date).to eq(Date.new(2024, 3, 15))
    expect(connection.exclusively_member).to be(true)
  end

  it "raises when number is missing" do
    expect {
      described_class.call(customer_id: customer.id, address_id: address.id, category_id: category.id, number: nil)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "raises when the same address already has a connection with that number and no letter" do
    create(:connection, customer: customer, address: address, category: category, number: 1, active: false)
    other_customer = create(:customer)

    expect {
      described_class.call(customer_id: other_customer.id, address_id: address.id, category_id: category.id, number: 1, active: false)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows the same address and number when letter differs" do
    create(:connection, customer: customer, address: address, category: category, number: 1, active: false)
    other_customer = create(:customer)

    connection = described_class.call(
      customer_id: other_customer.id, address_id: address.id, category_id: category.id, number: 1, letter: "A", active: false
    )

    expect(connection).to be_persisted
  end

  it "allows re-using a number+letter+address combination once the original connection is soft deleted" do
    existing = create(:connection, customer: customer, address: address, category: category, number: 1, active: false)
    existing.soft_delete!
    other_customer = create(:customer)

    connection = described_class.call(
      customer_id: other_customer.id, address_id: address.id, category_id: category.id, number: 1, active: false
    )

    expect(connection).to be_persisted
  end

  it "raises when the address already has an active connection" do
    create(:connection, customer: customer, address: address, category: category)
    other_customer = create(:customer)

    expect {
      described_class.call(customer_id: other_customer.id, address_id: address.id, category_id: category.id, number: 2)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "allows any number of inactive connections on the same address" do
    create(:connection, customer: customer, address: address, category: category, active: false, number: 1)

    expect {
      3.times { |i| described_class.call(customer_id: create(:customer).id, address_id: address.id, category_id: category.id, number: i + 2, active: false) }
    }.to change(Connection, :count).by(3)
  end

  it "raises when the customer already has an active efetivo connection" do
    create(:connection, customer: customer, address: address, category: category)
    other_address = create(:address)

    expect {
      described_class.call(customer_id: customer.id, address_id: other_address.id, category_id: category.id, number: 1)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "allows the customer to have another active connection outside the efetivo group" do
    create(:connection, customer: customer, address: address, category: category)
    other_address = create(:address)
    temporario_category = create(:category, group: "temporario")

    connection = described_class.call(
      customer_id: customer.id, address_id: other_address.id, category_id: temporario_category.id, number: 1
    )

    expect(connection).to be_persisted
  end
end
