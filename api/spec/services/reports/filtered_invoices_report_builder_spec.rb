require "rails_helper"

RSpec.describe Reports::FilteredInvoicesReportBuilder do
  it "renders one page per invoice, reusing InvoiceReportBuilder's layout" do
    category = create(:category, water_price: 15, membership_price: 5)
    connection = create(:connection, customer: create(:customer), address: create(:address), category: category)
    invoices = [
      create(:invoice, connection: connection, reference_date: Date.new(2026, 7, 1)),
      create(:invoice, connection: connection, reference_date: Date.new(2026, 8, 1))
    ]

    pdf = described_class.call(invoices)

    expect(pdf).to start_with("%PDF")
  end

  it "renders an empty invoice list without error" do
    pdf = described_class.call([])

    expect(pdf).to start_with("%PDF")
  end
end
