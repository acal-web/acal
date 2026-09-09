require "rails_helper"

RSpec.describe Reports::DunningReportBuilder do
  it "renders a PDF letter, one page per connection group" do
    category = create(:category, water_price: 15, membership_price: 5)
    connection = create(:connection, customer: create(:customer), address: create(:address), category: category)
    create(:invoice, connection: connection, due_date: Date.current - 45.days)
    groups = Invoices::OverdueConnectionsService.call(days: 30)

    pdf = described_class.call(groups)

    expect(pdf).to start_with("%PDF")
  end

  it "warns about the cutoff only for groups past the threshold" do
    category = create(:category, water_price: 15, membership_price: 5)
    connection = create(:connection, customer: create(:customer), address: create(:address), category: category)
    create(:invoice, connection: connection, due_date: Date.current - 90.days)
    groups = Invoices::OverdueConnectionsService.call(days: 30)

    expect(groups.first[:subject_to_cutoff]).to be(true)
    expect(described_class.call(groups)).to start_with("%PDF")
    expect(described_class.call([ groups.first.merge(subject_to_cutoff: false) ])).to start_with("%PDF")
  end
end
