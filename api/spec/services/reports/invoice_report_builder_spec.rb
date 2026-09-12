require "rails_helper"

RSpec.describe Reports::InvoiceReportBuilder do
  it "renders a PDF document for the invoice" do
    category = create(:category, water_price: 15, membership_price: 5)
    connection = create(:connection, customer: create(:customer), address: create(:address), category: category)
    invoice = create(:invoice, connection: connection)

    pdf = described_class.call(invoice)

    expect(pdf).to start_with("%PDF")
  end

  it "bottom-aligns the total box with the rest of its column" do
    boxes = []

    allow_any_instance_of(Prawn::Document).to receive(:rounded_rectangle).and_wrap_original do |original, point, width, height, radius|
      boxes << { bottom: (point[1] - height).round(1), label: nil }
      original.call(point, width, height, radius)
    end
    # draw_box paints the rounded frame and then its label, so the first text
    # after a frame names that box.
    allow_any_instance_of(Prawn::Document).to receive(:text).and_wrap_original do |original, text, **opts|
      boxes.last[:label] = text if boxes.any? && boxes.last[:label].nil?
      original.call(text, **opts)
    end

    category = create(:category, water_price: 15, membership_price: 5)
    connection = create(:connection, customer: create(:customer), address: create(:address), category: category)

    described_class.call(create(:invoice, connection: connection))

    totals = boxes.select { |box| box[:label] == "VALOR TOTAL" }

    # The meter and payment boxes stretch to the column's bottom edge; the
    # total box must land there too instead of floating above it.
    expect(totals).not_to be_empty
    expect(totals.map { |box| box[:bottom] }.uniq).to eq([ 0.0 ])
  end
end
