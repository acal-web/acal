FactoryBot.define do
  # `index` drives both reference_date and param_name so successive builds
  # land on distinct (reference_date, param_name) pairs by default, avoiding
  # the unique index — cycle through the 5 params before rolling back a month.
  factory :quality_analysis do
    transient do
      sequence(:index)
    end

    reference_date { Date.current.beginning_of_month - (index / QualityAnalysis::PARAM_NAMES.size).months }
    param_name { QualityAnalysis::PARAM_NAMES[index % QualityAnalysis::PARAM_NAMES.size] }
    required { 1 }
    analyzed { 1 }
    compliant { 1 }
  end
end
