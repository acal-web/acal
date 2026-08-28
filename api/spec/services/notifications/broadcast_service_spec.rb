require "rails_helper"

RSpec.describe Notifications::BroadcastService do
  it "sends a push notification to every customer in the collection" do
    first = create(:customer)
    second = create(:customer)
    allow(Devices::SendPushService).to receive(:call)

    described_class.call(title: "Aviso", body: "Mensagem", customers: Customer.where(id: [ first.id, second.id ]))

    expect(Devices::SendPushService).to have_received(:call).with(owner: first, title: "Aviso", body: "Mensagem")
    expect(Devices::SendPushService).to have_received(:call).with(owner: second, title: "Aviso", body: "Mensagem")
  end
end
