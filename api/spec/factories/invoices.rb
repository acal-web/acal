FactoryBot.define do
  factory :invoice do
    association :connection
    reference_date { Date.current.beginning_of_month }
    due_date { Date.current.beginning_of_month + 10.days }
    amount { 20.0 }

    trait :paid do
      paid_at { Time.current }
    end
  end
end
