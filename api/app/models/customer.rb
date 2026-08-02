class Customer < ApplicationRecord
  include SoftDeletable

  before_validation { self.name = name.to_s.strip }
  before_validation { self.document = document.to_s.gsub(/\D/, "") }

  validates :name, presence: true, length: { minimum: 3, maximum: 1024 }
  validates :document, presence: true, cpf_cnpj: true, uniqueness: true
  validates :membership_number, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :filter_by_name, ->(name) {
    where("name ILIKE :q", q: "%#{sanitize_sql_like(name)}%") if name.present?
  }

  scope :filter_by_document, ->(document) {
    digits = document.to_s.gsub(/\D/, "")
    where("document ILIKE :q", q: "%#{sanitize_sql_like(digits)}%") if digits.present?
  }
end
