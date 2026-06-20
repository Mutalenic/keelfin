FactoryBot.define do
  factory :ledger_account, class: 'Ledger::Account' do
    association :user
    name         { 'Wallet' }
    account_type { 'asset' }
    currency     { 'ZMW' }
    active       { true }

    trait :asset do
      account_type { 'asset' }
      name { 'Wallet' }
    end

    trait :liability do
      account_type { 'liability' }
      name { 'Loan' }
    end

    trait :equity do
      account_type { 'equity' }
      name { 'Opening Equity' }
    end

    trait :income do
      account_type { 'income' }
      name { 'Salary' }
    end

    trait :expense do
      account_type { 'expense' }
      name { 'Groceries' }
    end
  end
end
