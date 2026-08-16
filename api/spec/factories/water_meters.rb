FactoryBot.define do
  factory :water_meter do
    invoice { association :invoice }
    measured_at { Date.current }
    initial_reading { 1000 }
    final_reading { 1500 }
  end
end
