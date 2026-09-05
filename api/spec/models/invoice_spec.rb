require "rails_helper"

RSpec.describe Invoice do
  describe "#paid?" do
    it "is true once paid_at is set" do
      invoice = create(:invoice, :paid)

      expect(invoice.paid?).to be(true)
    end

    it "is false while paid_at is nil" do
      invoice = create(:invoice, paid_at: nil)

      expect(invoice.paid?).to be(false)
    end
  end
end
