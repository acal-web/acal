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
