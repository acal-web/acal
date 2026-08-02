class Category < ApplicationRecord
  include SoftDeletable

  GROUPS = %w[temporario efetivo fundador].freeze

  before_validation { name&.strip! }

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :group, presence: true, inclusion: { in: GROUPS }
  validates :water_price, :membership_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :filter_by_name, ->(name) {
    where("name ILIKE :q", q: "%#{sanitize_sql_like(name)}%") if name.present?
  }
end
