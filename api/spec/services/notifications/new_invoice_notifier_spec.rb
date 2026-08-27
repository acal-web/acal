require "rails_helper"

RSpec.describe Notifications::NewInvoiceNotifier do
  let(:category) { create(:category, water_price: 15, membership_price: 5) }
  let(:connection) { create(:connection, customer: create(:customer), address: create(:address), category: category) }
  let(:invoice) { create(:invoice, connection: connection, membership_value: 5, water_value: 15) }

  it "pushes the customer their name, the connection's address, and the invoice amount" do
    allow(Devices::SendPushService).to receive(:call)

    described_class.call(connection: connection, invoice: invoice)

    expect(Devices::SendPushService).to have_received(:call).with(
      owner: connection.customer,
      title: "Nova fatura",
      body: "#{connection.customer.name}, você possui uma nova fatura, na residência #{connection.full_location}, " \
            "no valor de #{Reports::PdfFactory.currency(20.0)}"
    )
  end

  it "does nothing when the connection has no customer" do
    allow(connection).to receive(:customer).and_return(nil)

    expect(Devices::SendPushService).not_to receive(:call)

    described_class.call(connection: connection, invoice: invoice)
  end
end
