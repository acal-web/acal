class User < ApplicationRecord
  include SoftDeletable

  has_secure_password

  ROLES = %w[administrador financeiro_secretaria tesoureiro].freeze
  enum :role, ROLES.index_by(&:itself)

  before_validation { self.username = username.to_s.strip.downcase }
  before_validation { self.name = name.to_s.strip }

  validates :name, presence: true, length: { minimum: 3, maximum: 1024 }
  validates :username, presence: true, format: { with: /\A[a-z0-9._-]+\z/, message: "only allows lowercase letters, numbers, dots, underscores and dashes" }
  validates :role, presence: true, inclusion: { in: ROLES }
end
