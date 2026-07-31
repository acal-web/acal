class Address < ApplicationRecord
  include SoftDeletable

  before_validation { name&.strip! }

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :kind, presence: true
end
