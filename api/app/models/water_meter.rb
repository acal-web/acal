class WaterMeter < ApplicationRecord
  include SoftDeletable

  belongs_to :invoice, -> { unscope(where: :deleted_at) }

  validates :measured_at, :initial_reading, :final_reading, presence: true
  validates :initial_reading, :final_reading, numericality: { greater_than_or_equal_to: 0 }
  validate :final_reading_greater_than_initial

  FREE_TIER_LIMIT = 10000

  def consumption
    [ (final_reading - initial_reading) - FREE_TIER_LIMIT, 0 ].max
  end

  def real_consumption
    final_reading - initial_reading
  end

  alias_method :total_consumption, :real_consumption

  def water_consumed_value
    (consumption / 4.0) * 0.01
  end

  private

  def final_reading_greater_than_initial
    return if final_reading.blank? || initial_reading.blank?

    if final_reading < initial_reading
      errors.add(:final_reading, "must be greater than or equal to initial_reading")
    end
  end
end
