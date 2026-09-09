require "rails_helper"

RSpec.describe Rbac do
  describe ".can?" do
    it "grants a permission listed for the group" do
      expect(Rbac.can?("administrador", "users:records:read")).to be true
    end

    it "denies a permission not listed for the group" do
      expect(Rbac.can?("tesoureiro", "customers:records:create")).to be false
    end

    it "denies an unknown group" do
      expect(Rbac.can?("unknown", "customers:records:read")).to be false
    end

    it "denies a blank group" do
      expect(Rbac.can?(nil, "customers:records:read")).to be false
    end

    it "treats ANY_GROUP as authenticated-only" do
      expect(Rbac.can?("customer", Rbac::ANY_GROUP)).to be true
      expect(Rbac.can?(nil, Rbac::ANY_GROUP)).to be false
    end
  end

  describe ".permissions_for" do
    it "returns the atomic permission codes granted to a group" do
      expect(Rbac.permissions_for("tesoureiro")).to include("invoices:payment:execute")
      expect(Rbac.permissions_for("tesoureiro")).not_to include("customers:records:create")
    end

    it "returns an empty array for an unknown group" do
      expect(Rbac.permissions_for("unknown")).to eq([])
    end
  end
end
