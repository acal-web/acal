class Customer < ApplicationRecord
  include SoftDeletable

  before_validation { self.name = name.to_s.strip }
  before_validation { self.document = document.to_s.gsub(/\D/, "") }

  validates :name, presence: true, length: { minimum: 3, maximum: 1024 }
  validates :document, presence: true, cpf_cnpj: true, uniqueness: true
  validates :membership_number, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :search, ->(query) {
    where("name ILIKE :q OR document ILIKE :q", q: "%#{sanitize_sql_like(query)}%") if query.present?
  }
end
