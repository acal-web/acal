FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Categoria #{n}" }
    group { "efetivo" }
    water_price { 0 }
    membership_price { 0 }
  end
end
