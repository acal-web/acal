# Groups an address's editable attributes and normalizes them on the way in
# (e.g. stripping the name), so the controller doesn't have to.
class AddressForm
  attr_reader :kind, :name, :legacy_id

  def initialize(kind: nil, name: nil, legacy_id: nil)
    @kind = kind
    @name = name&.strip
    @legacy_id = legacy_id
  end

  def to_h
    { kind:, name:, legacy_id: }
  end
end
