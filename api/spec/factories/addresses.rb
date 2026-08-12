FactoryBot.define do
  factory :address do
    sequence(:name) { |n| "Home Street #{n}" }
  end
end
