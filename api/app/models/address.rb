class Address < ApplicationRecord
  include SoftDeletable

  before_validation { name&.strip! }

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :kind, presence: true

  scope :filter_by_name, ->(name) {
    where("name ILIKE :q", q: "%#{sanitize_sql_like(name)}%") if name.present?
  }

  scope :filter_by_kind, ->(kind) {
    where(kind: kind) if kind.present?
  }


end
