require "rails_helper"

RSpec.describe "boleto preview" do
  it "renders unpaid, no water meter sample" do
    category = create(:category, water_price: 15, membership_price: 5, name: "Residente Preview #{SecureRandom.hex(3)}")
    customer = create(:customer, name: "Adauto Pereira de Carvalho")
    address = create(:address, name: "Fazenda Água Nova")
    connection = create(:connection, customer: customer, address: address, category: category, number: 41, letter: "LAN", legacy_id: 3098)
    invoice = create(:invoice, connection: connection, membership_value: 0, water_value: 48.8)

    pdf_bytes = Invoices::BoletoPdfService.call(invoice)
    File.binwrite("/tmp/claude-1001/-workspace/e6834f73-a9fa-412c-86ed-7c4783e0d82b/scratchpad/preview.pdf", pdf_bytes)
  end
end
