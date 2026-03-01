FactoryBot.define do
  factory :debt do
    association :user
    lender_name { 'Bayport Financial' }
    principal_amount { 50_000 }
    monthly_payment { 2_000 }
    status { 'active' }
    interest_rate { 18.0 }
  end
end
