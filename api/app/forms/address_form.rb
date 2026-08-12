class AddressForm
  attr_reader :name, :legacy_id

  def initialize(name: nil, legacy_id: nil)
    @name = name&.strip
    @legacy_id = legacy_id
  end

  def to_h
    { name:, legacy_id: }
  end
end
