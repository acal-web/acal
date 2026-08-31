class User < ApplicationRecord
  include SoftDeletable

  has_secure_password

  MAX_LOGIN_ATTEMPTS = 5
  LOCKOUT_DURATION = 15.minutes

  # "customer" users are the login half of a Customer (sócio) — see
  # Customer#create_linked_user!. username/password for them are the
  # customer's document/customer_code, so the same POST /session endpoint
  # authenticates staff and sócios alike.
  ROLES = %w[administrador financeiro_secretaria tesoureiro customer].freeze
  enum :role, ROLES.index_by(&:itself)

  belongs_to :customer, optional: true

  # The staff user-management screens deal with employees, not the
  # customer-role accounts auto-created per Customer — keep those separate.
  scope :staff, -> { where.not(role: "customer") }

  before_validation { self.username = username.to_s.strip.downcase }
  before_validation { self.name = name.to_s.strip }

  validates :name, presence: true, length: { minimum: 3, maximum: 1024 }
  validates :username, presence: true, format: { with: /\A[a-z0-9._-]+\z/, message: "only allows lowercase letters, numbers, dots, underscores and dashes" }
  validates :role, presence: true, inclusion: { in: ROLES }
  # Keeps role: "customer" from being set through the staff /users form —
  # it only ever comes from Customer#create_linked_user!, which sets both.
  validates :customer_id, presence: true, if: :customer?
  validates :customer_id, absence: true, unless: :customer?

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

  # render json: @user (and any other bare AS JSON call) must never leak the
  # bcrypt hash — UserSerializer's declared attribute list isn't actually
  # wired up (jsonapi-serializer doesn't hook into render json:/each_serializer:),
  # so this is the only thing standing between password_digest and the wire.
  def as_json(options = {})
    super(options.merge(except: [ *options[:except], :password_digest ]))
  end
end
