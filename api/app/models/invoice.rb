class Invoice < ApplicationRecord
  include SoftDeletable

  TOTAL_AMOUNT_SQL = "membership_value + water_value + COALESCE(water_consumed_value, 0)"

  belongs_to :connection, -> { unscope(where: :deleted_at) }
  belongs_to :user, optional: true
  has_one :water_meter, dependent: :destroy

  validates :reference_date, :due_date, presence: true
  validates :membership_value, :water_value, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_create :generate_number
  before_save :update_last_updated_at

  scope :filter_by_period, ->(year, month) {
    if year.present? && month.present?
      start_date = Date.new(year.to_i, month.to_i, 1)
      where(reference_date: start_date..start_date.end_of_month)
    end
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

  scope :filter_by_paid_between, ->(start_date, end_date) {
    if start_date.present? && end_date.present?
      where(paid_at: Date.parse(start_date).beginning_of_day..Date.parse(end_date).end_of_day)
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
    QualityAnalysis.where(reference_date: reference_date.beginning_of_month..reference_date.end_of_month)
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
