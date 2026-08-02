FactoryBot.define do
  factory :address do
    kind { "home" }
    sequence(:name) { |n| "Street #{n}" }
  end
end
