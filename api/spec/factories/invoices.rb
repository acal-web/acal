FactoryBot.define do
  factory :invoice do
    association :connection, factory: :connection_with_all_data
    reference_date { Date.current.beginning_of_month }
    due_date { Date.current.beginning_of_month + 10.days }
    membership_value { 15.0 }
    water_value { 5.0 }

    trait :paid do
      paid_at { Time.current }
    end
  end
end
