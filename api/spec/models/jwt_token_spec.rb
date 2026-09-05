require "rails_helper"

RSpec.describe JwtToken do
  describe ".encode/.decode" do
    it "round-trips the user_id and group" do
      token = described_class.encode("user-123", group: "administrador")

      payload = described_class.decode(token)

      expect(payload[:user_id]).to eq("user-123")
      expect(payload[:group]).to eq("administrador")
    end

    it "returns nil for a blank token" do
      expect(described_class.decode(nil)).to be_nil
      expect(described_class.decode("")).to be_nil
    end

    it "returns nil for a garbled token" do
      expect(described_class.decode("not-a-real-token")).to be_nil
    end

    it "returns nil for an expired token" do
      token = described_class.encode("user-123", group: "administrador", expires_at: 1.day.ago)

      expect(described_class.decode(token)).to be_nil
    end
  end

  describe ".valid?" do
    it "is true for a token that decodes successfully" do
      token = described_class.encode("user-123", group: "administrador")

      expect(described_class.valid?(token)).to be(true)
    end

    it "is false for an expired or garbled token" do
      expect(described_class.valid?("garbage")).to be(false)
    end
  end
end
