FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:name) { |n| "Usuário #{n}" }
    password { "password123" }
    role { "administrador" }

    trait :financeiro_secretaria do
      role { "financeiro_secretaria" }
    end

    trait :tesoureiro do
      role { "tesoureiro" }
    end
  end
end
