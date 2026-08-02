class Connection < ApplicationRecord
  include SoftDeletable

  belongs_to :customer
  belongs_to :address
  belongs_to :category

  validate :address_not_already_active, if: :active?

  scope :filter_by_customer_name, ->(name) {
    joins(:customer).where("customers.name ILIKE :q", q: "%#{sanitize_sql_like(name)}%") if name.present?
  }

  scope :filter_by_customer_document, ->(document) {
    digits = document.to_s.gsub(/\D/, "")
    joins(:customer).where("customers.document ILIKE :q", q: "%#{sanitize_sql_like(digits)}%") if digits.present?
  }

  scope :filter_by_address_name, ->(name) {
    joins(:address).where("addresses.name ILIKE :q", q: "%#{sanitize_sql_like(name)}%") if name.present?
  }

  scope :filter_by_category_id, ->(category_id) {
    where(category_id: category_id) if category_id.present?
  }

  scope :filter_by_active, ->(active) {
    where(active: ActiveModel::Type::Boolean.new.cast(active)) unless active.nil? || active == ""
  }

  private

  def address_not_already_active
    return unless address_id

    conflicting = Connection.where(address_id: address_id, active: true)
    conflicting = conflicting.where.not(id: id) if persisted?
    errors.add(:address_id, "already has an active connection") if conflicting.exists?
  end
end
