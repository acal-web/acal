require "rails_helper"

RSpec.describe Invoices::BoletoPdfService do
  it "renders a PDF document for the invoice" do
    category = create(:category, water_price: 15, membership_price: 5)
    connection = create(:connection, customer: create(:customer), address: create(:address), category: category)
    invoice = create(:invoice, connection: connection)

    pdf = described_class.call(invoice)

    expect(pdf).to start_with("%PDF")
  end
end
