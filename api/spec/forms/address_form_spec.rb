require "rails_helper"

RSpec.describe AddressForm do
  it "exposes the given name and legacy_id" do
    form = described_class.new(name: "Rua Main Street", legacy_id: 123)

    expect(form.name).to eq("Rua Main Street")
    expect(form.legacy_id).to eq(123)
  end

  it "strips leading and trailing whitespace from the name" do
    form = described_class.new(name: "  Rua Main Street  ")

    expect(form.name).to eq("Rua Main Street")
  end

  it "defaults legacy_id to nil" do
    form = described_class.new(name: "Rua Main Street")

    expect(form.legacy_id).to be_nil
  end

  it "leaves a nil name as nil" do
    form = described_class.new(name: nil)

    expect(form.name).to be_nil
  end

  it "defaults name to nil when omitted entirely" do
    form = described_class.new

    expect(form.name).to be_nil
  end

  describe "#to_h" do
    it "returns the (normalized) attributes, ready to splat into Address.create!/update!" do
      form = described_class.new(name: "  Rua Main Street  ", legacy_id: 123)

      expect(form.to_h).to eq(name: "Rua Main Street", legacy_id: 123)
    end
  end
end
