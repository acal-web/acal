require "rails_helper"

RSpec.describe Notifications::BroadcastJob do
  it "pushes to every customer matching the notification's address/category/status filters" do
    address = create(:address)
    category = create(:category)
    matching_customer = create(:customer)
    create(:connection, customer: matching_customer, address: address, category: category)

    other_customer = create(:customer)
    create(:connection, customer: other_customer, address: create(:address), category: category)

    notification = create(:notification, title: "Aviso", body: "Mensagem", address: address, category: category)
    allow(Devices::SendPushService).to receive(:call)

    described_class.new.perform(notification.id)

    expect(Devices::SendPushService).to have_received(:call)
      .with(owner: matching_customer, title: "Aviso", body: "Mensagem")
    expect(Devices::SendPushService).not_to have_received(:call).with(owner: other_customer, title: anything, body: anything)
  end
end
