FactoryBot.define do
  factory :category do
    association :user
    name          { "Groceries" }
    icon          { "fa-solid fa-cart-shopping" }
    color         { "#4CAF50" }
    category_type { "groceries" }
    description   { "Food and household items" }

    trait :fixed do
      name          { "Housing" }
      category_type { "fixed" }
    end

    trait :variable do
      name          { "Transport" }
      category_type { "variable" }
    end

    trait :discretionary do
      name          { "Entertainment" }
      category_type { "discretionary" }
    end
  end
end
