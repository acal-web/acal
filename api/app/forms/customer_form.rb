class CustomerForm
  attr_reader :name, :document, :membership_number, :voter, :legacy_id, :tags

  def initialize(name: nil, document: nil, membership_number: nil, voter: false, legacy_id: nil, tags: [])
    @name = name
    @document = document
    @membership_number = membership_number
    @voter = voter
    @legacy_id = legacy_id
    @tags = tags
  end

  def to_h
    { name:, document:, membership_number:, voter:, legacy_id:, tags: }
  end
end
