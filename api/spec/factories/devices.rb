FactoryBot.define do
  factory :device do
    platform { "android" }
    sequence(:push_token) { |n| "push-token-#{n}" }
    device_model { "Pixel 7" }
    os_version { "Android 14" }
    app_version { "0.1.1" }
    last_seen_at { Time.current }
    association :owner, factory: :user
  end
end
