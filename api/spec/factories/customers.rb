FactoryBot.define do
  factory :customer do
    sequence(:name) { |n| "Fulano de Tal #{n}" }
    sequence(:document) { |n| DocumentGenerator.cpf(100_000_000 + n) }
    membership_number { rand(1..100_000) }
    voter { false }
  end
end
