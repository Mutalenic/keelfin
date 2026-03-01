FactoryBot.define do
  sequence(:user_email) { |n| "user#{n}@example.com" }

  factory :user do
    name { 'Test User' }
    email { generate(:user_email) }
    password { 'password123' }
    monthly_income { 10_000 }
    role { 'user' }

    trait :admin do
      role { 'admin' }
    end

    trait :with_subscription do
      after(:create) { |u| Subscription.create_free_subscription(u) }
    end
  end
end
