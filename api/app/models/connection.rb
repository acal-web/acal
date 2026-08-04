class Connection < ApplicationRecord
  include SoftDeletable

  # Unscoped: a connection's own deleted_at governs whether *it* shows up
  # (default_scope from SoftDeletable, below). Its related customer/address/
  # category should keep showing in full on the connection regardless of
  # *their* deleted_at — a connection to a since-deleted address, say, must
  # not lose that address's data. The filter_by_* scopes below deliberately
  # re-add each model's default scope via `.merge` so searching still skips
  # soft-deleted matches — that behavior no longer comes for free from the
  # association now that it's unscoped.
  belongs_to :customer, -> { unscope(where: :deleted_at) }
  belongs_to :address, -> { unscope(where: :deleted_at) }
  belongs_to :category, -> { unscope(where: :deleted_at) }

  validate :address_not_already_active, if: :active?
  validate :customer_not_already_efetivo, if: :active?

  scope :filter_by_customer_name, ->(name) {
    joins(:customer).merge(Customer.all).where("customers.name ILIKE :q", q: "%#{sanitize_sql_like(name)}%") if name.present?
  }

  scope :filter_by_customer_document, ->(document) {
    digits = document.to_s.gsub(/\D/, "")
    joins(:customer).merge(Customer.all).where("customers.document ILIKE :q", q: "%#{sanitize_sql_like(digits)}%") if digits.present?
  }

  scope :filter_by_address_name, ->(name) {
    joins(:address).merge(Address.all).where("addresses.name ILIKE :q", q: "%#{sanitize_sql_like(name)}%") if name.present?
  }

  scope :filter_by_category_id, ->(category_id) {
    joins(:category).merge(Category.all).where(category_id: category_id) if category_id.present?
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

  def customer_not_already_efetivo
    return unless customer_id
    return unless category&.group == "efetivo"

    conflicting = Connection.where(customer_id: customer_id, active: true).joins(:category).where(categories: { group: "efetivo" })
    conflicting = conflicting.where.not(id: id) if persisted?
    errors.add(:customer_id, "already has an active connection as efetivo") if conflicting.exists?
  end
end
