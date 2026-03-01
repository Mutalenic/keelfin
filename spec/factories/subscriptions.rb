FactoryBot.define do
  factory :subscription do
    association :user
    plan_name { 'free' }
    status { 'active' }
    start_date { Time.current }
    amount { 0.0 }
    features { Subscription::PLANS[:free][:features] }

    trait :standard do
      plan_name { 'standard' }
      amount { Subscription::PLANS[:standard][:price] }
      features { Subscription::PLANS[:standard][:features] }
    end

    trait :premium do
      plan_name { 'premium' }
      amount { Subscription::PLANS[:premium][:price] }
      features { Subscription::PLANS[:premium][:features] }
    end
  end
end
