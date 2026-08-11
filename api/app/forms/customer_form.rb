class CustomerForm
  attr_reader :name, :document, :membership_number, :voter, :legacy_id

  def initialize(name: nil, document: nil, membership_number: nil, voter: false, legacy_id: nil)
    @name = name
    @document = document
    @membership_number = membership_number
    @voter = voter
    @legacy_id = legacy_id
  end

  def to_h
    { name:, document:, membership_number:, voter:, legacy_id: }
  end
end
