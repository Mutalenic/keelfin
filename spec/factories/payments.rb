FactoryBot.define do
  factory :payment do
    association :user
    association :category
    name { 'Shoprite' }
    amount { 350.00 }
    payment_method { 'cash' }
    is_essential { true }
  end
end
