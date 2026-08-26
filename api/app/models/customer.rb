class Customer < ApplicationRecord
  include SoftDeletable

  MAX_LOGIN_ATTEMPTS = 5
  LOCKOUT_DURATION = 15.minutes

  before_validation { self.name = name.to_s.strip }
  before_validation { self.document = document.to_s.gsub(/\D/, "") }
  before_validation :generate_customer_code, on: :create

  validates :name, presence: true, length: { minimum: 3, maximum: 1024 }
  validates :document, presence: true, cpf_cnpj: true
  validates :membership_number, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :customer_code, presence: true, uniqueness: true
  validate :validate_document_uniqueness

  scope :filter_by_name, ->(name) {
    where("LOWER(name) LIKE LOWER(:q)", q: "%#{sanitize_sql_like(name)}%") if name.present?
  }

  scope :filter_by_document, ->(document) {
    digits = document.to_s.gsub(/\D/, "")
    where("LOWER(document) LIKE LOWER(:q)", q: "%#{sanitize_sql_like(digits)}%") if digits.present?
  }

  def locked?
    locked_until.present? && locked_until.future?
  end

  def register_failed_login!
    increment!(:failed_login_attempts)
    update!(locked_until: LOCKOUT_DURATION.from_now) if failed_login_attempts >= MAX_LOGIN_ATTEMPTS
  end

  def reset_login_attempts!
    update!(failed_login_attempts: 0, locked_until: nil)
  end

  private
    def generate_customer_code
      return if customer_code.present?

      loop do
        code = format("%06d", rand(1_000_000))
        next if Customer.unscoped.exists?(customer_code: code)

        self.customer_code = code
        break
      end
    end

    def validate_document_uniqueness
      return if document.blank?

      conflict = Customer.unscoped.where(document: document).where.not(id: id).first
      return unless conflict

      errors.add(:document, conflict.deleted_at.nil? ?
        "Já existe um cadastro para esse documento associado ao usuário #{conflict.name}" :
        "Esse sócio já está cadastrado, porém inativo. É possível reativar.")
    end
end
