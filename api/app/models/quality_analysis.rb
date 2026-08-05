class QualityAnalysis < ApplicationRecord
  include SoftDeletable

  PARAM_NAMES = [
    "Cloro Residual",
    "Coliformes Totais",
    "Cor Aparente",
    "Escherichia Coli",
    "Turbidez"
  ].freeze

  validates :reference_date, presence: true
  validates :param_name, presence: true, inclusion: { in: PARAM_NAMES }
  validates :required, :analyzed, :compliant,
    presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :filter_by_period, ->(year, month) {
    where("EXTRACT(YEAR FROM reference_date) = ? AND EXTRACT(MONTH FROM reference_date) = ?", year, month) if year.present? && month.present?
  }

  scope :ordered, -> { order(reference_date: :desc, param_name: :asc) }
end
