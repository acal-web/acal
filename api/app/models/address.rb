class Address < ApplicationRecord
  include SoftDeletable

  before_validation { name&.strip! }

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }

  scope :filter_by_name, ->(name) {
    where("name ILIKE :q", q: "%#{sanitize_sql_like(name)}%") if name.present?
  }
end
