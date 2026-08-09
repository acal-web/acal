class Customer < ApplicationRecord
  include SoftDeletable

  before_validation { self.name = name.to_s.strip }
  before_validation { self.document = document.to_s.gsub(/\D/, "") }

  validates :name, presence: true, length: { minimum: 3, maximum: 1024 }
  validates :document, presence: true, cpf_cnpj: true
  validates :membership_number, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :validate_document_uniqueness

  scope :filter_by_name, ->(name) {
    where("name ILIKE :q", q: "%#{sanitize_sql_like(name)}%") if name.present?
  }

  scope :filter_by_document, ->(document) {
    digits = document.to_s.gsub(/\D/, "")
    where("document ILIKE :q", q: "%#{sanitize_sql_like(digits)}%") if digits.present?
  }

  private
    # Checked against every customer, active or soft deleted, so a duplicate
    # document points people at the conflicting record either way — the
    # message just differs depending on whether it can be reactivated.
    def validate_document_uniqueness
      return if document.blank?

      conflict = Customer.unscoped.where(document: document).where.not(id: id).first
      return unless conflict

      errors.add(:document, conflict.deleted_at.nil? ?
        "Já existe um cadastro para esse documento associado ao usuário #{conflict.name}" :
        "Esse sócio já está cadastrado, porém inativo. É possível reativar.")
    end
end
