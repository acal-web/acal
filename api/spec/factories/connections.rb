FactoryBot.define do
  # No default customer/address/category — a connection ties three other
  # records together, so callers must say explicitly which ones (nothing
  # should be silently created just to satisfy this factory).
  factory :connection do
    sequence(:number)
    active { true }
  end

  factory :connection_with_all_data, class: "Connection" do
    sequence(:number)
    active { true }
    association :customer
    association :address
    association :category
  end
end
