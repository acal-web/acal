class Invoice < ApplicationRecord
  include SoftDeletable

  # Unscoped for the same reason as Connection's own associations: an
  # invoice for a since-deleted connection must keep showing that
  # connection's data.
  belongs_to :connection, -> { unscope(where: :deleted_at) }

  validates :reference_date, :due_date, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :filter_by_period, ->(year, month) {
    where("EXTRACT(YEAR FROM reference_date) = ? AND EXTRACT(MONTH FROM reference_date) = ?", year, month) if year.present? && month.present?
  }

  scope :ordered, -> { order(reference_date: :desc, created_at: :desc) }

  scope :unpaid, -> { where(paid_at: nil) }
  scope :overdue, ->(days = 30) { unpaid.where("due_date < ?", Date.current - days.days) }

  def paid?
    paid_at.present?
  end
end
