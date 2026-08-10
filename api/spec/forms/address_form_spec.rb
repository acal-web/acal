require "rails_helper"

RSpec.describe AddressForm do
  it "exposes the given kind, name and legacy_id" do
    form = described_class.new(kind: "home", name: "Main Street", legacy_id: 123)

    expect(form.kind).to eq("home")
    expect(form.name).to eq("Main Street")
    expect(form.legacy_id).to eq(123)
  end

  it "strips leading and trailing whitespace from the name" do
    form = described_class.new(kind: "home", name: "  Main Street  ")

    expect(form.name).to eq("Main Street")
  end

  it "defaults legacy_id to nil" do
    form = described_class.new(kind: "home", name: "Main Street")

    expect(form.legacy_id).to be_nil
  end

  it "leaves a nil name as nil" do
    form = described_class.new(kind: "home", name: nil)

    expect(form.name).to be_nil
  end

  it "defaults kind and name to nil when omitted entirely" do
    form = described_class.new

    expect(form.kind).to be_nil
    expect(form.name).to be_nil
  end

  describe "#to_h" do
    it "returns the (normalized) attributes, ready to splat into Address.create!/update!" do
      form = described_class.new(kind: "home", name: "  Main Street  ", legacy_id: 123)

      expect(form.to_h).to eq(kind: "home", name: "Main Street", legacy_id: 123)
    end
  end
end
