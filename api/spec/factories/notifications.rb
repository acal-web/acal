FactoryBot.define do
  factory :notification do
    title { "Aviso" }
    body { "Mensagem para os sócios." }
    recipient_count { 0 }
    association :sent_by, factory: :user
  end
end
