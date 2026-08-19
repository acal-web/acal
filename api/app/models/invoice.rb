class Invoice < ApplicationRecord
  include SoftDeletable

  belongs_to :connection, -> { unscope(where: :deleted_at) }
  belongs_to :user, optional: true
  has_one :water_meter, dependent: :destroy

  validates :reference_date, :due_date, presence: true
  validates :membership_value, :water_value, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_create :generate_number
  before_save :update_last_updated_at

  scope :filter_by_period, ->(year, month) {
    where("EXTRACT(YEAR FROM reference_date) = ? AND EXTRACT(MONTH FROM reference_date) = ?", year, month) if year.present? && month.present?
  }

  scope :filter_by_customer, ->(customer_id) {
    joins(:connection).where(connections: { customer_id: }) if customer_id.present?
  }

  scope :filter_by_address, ->(address_id) {
    joins(:connection).where(connections: { address_id: }) if address_id.present?
  }

  scope :filter_by_status, ->(status) {
    case status
    when "paid" then where.not(paid_at: nil)
    when "unpaid" then where(paid_at: nil)
    else self
    end
  }

  scope :ordered, -> { order(reference_date: :desc, created_at: :desc) }

  scope :unpaid, -> { where(paid_at: nil) }
  scope :overdue, ->(days = 30) { unpaid.where("due_date < ?", Date.current - days.days) }

  def paid?
    paid_at.present?
  end

  def amount
    membership_value + water_value + (water_consumed_value || 0)
  end

  def quality_analyses
    QualityAnalysis.where("EXTRACT(YEAR FROM reference_date) = ? AND EXTRACT(MONTH FROM reference_date) = ?", reference_date.year, reference_date.month)
  end

  private

  def generate_number
    year = reference_date.year
    month = reference_date.month
    count = Invoice.where("EXTRACT(YEAR FROM reference_date) = ? AND EXTRACT(MONTH FROM reference_date) = ?", year, month).count + 1
    self.number = "#{year}.#{month.to_s.rjust(2, '0')}.#{count.to_s.rjust(6, '0')}"
  end

  def update_last_updated_at
    self.last_updated_at = Time.current
  end
end
