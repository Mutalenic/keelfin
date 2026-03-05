# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "=== Keelfin Professional Seed Data ==="
puts ""

# ─── Category Presets ───────────────────────────────────────────
puts "Seeding category presets..."
CategoryPreset.seed_defaults
puts "  ✓ Category presets created"

# ─── Users ──────────────────────────────────────────────────────
puts ""
puts "Creating users..."

admin = User.find_or_create_by!(email: 'admin@keelfin.co.zm') do |u|
  u.name = 'Keelfin Admin'
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.role = 'admin'
  u.monthly_income = 15_000.00
  u.currency = 'ZMW'
  u.phone_number = '+260971000001'
  u.confirmed_at = Time.current
end
puts "  ✓ Admin: admin@keelfin.co.zm / password123"

demo_users = [
  { email: 'mwila@example.com', name: 'Mwila Chanda', income: 8_500.00, phone: '+260971000002', persona: :professional },
  { email: 'bupe@example.com', name: 'Bupe Mutale', income: 4_200.00, phone: '+260971000003', persona: :student },
  { email: 'chileshe@example.com', name: 'Chileshe Mbewe', income: 12_000.00, phone: '+260971000004', persona: :family },
]

users = {}
demo_users.each do |u_data|
  user = User.find_or_create_by!(email: u_data[:email]) do |u|
    u.name = u_data[:name]
    u.password = 'password123'
    u.password_confirmation = 'password123'
    u.monthly_income = u_data[:income]
    u.currency = 'ZMW'
    u.phone_number = u_data[:phone]
    u.confirmed_at = Time.current
  end
  users[u_data[:persona]] = user
  puts "  ✓ #{u_data[:persona].capitalize}: #{u_data[:email]} / password123"
end

# ─── Subscriptions ──────────────────────────────────────────────
puts ""
puts "Creating subscriptions..."

admin.ensure_subscription if admin.respond_to?(:ensure_subscription)
Subscription.find_or_create_by!(user: admin) do |s|
  s.plan_name = 'premium'
  s.status = 'active'
  s.amount = 99.99
  s.start_date = 3.months.ago
end rescue nil

users.each do |persona, user|
  plan = case persona
         when :professional then 'standard'
         when :family then 'premium'
         else 'free'
         end
  amount = case plan
           when 'premium' then 99.99
           when 'standard' then 49.99
           else 0
           end
  user.ensure_subscription if user.respond_to?(:ensure_subscription)
  Subscription.find_or_create_by!(user: user) do |s|
    s.plan_name = plan
    s.status = 'active'
    s.amount = amount
    s.start_date = rand(1..6).months.ago
  end rescue nil
end
puts "  ✓ Subscriptions assigned"

# ─── Helper: Create categories for a user from presets ──────────
def create_user_categories(user)
  categories = {}
  CategoryPreset.ordered.each do |preset|
    cat = user.categories.find_or_create_by!(name: preset.name) do |c|
      c.icon = preset.icon
      c.icon_name = preset.icon_name
      c.color = preset.color
      c.category_type = preset.category_type
      c.description = preset.description
    end
    categories[preset.name.parameterize.underscore.to_sym] = cat
  end
  categories
end

# ─── Realistic Transactions Data ────────────────────────────────
PAYMENT_METHODS = %w[cash bank mtn_momo airtel_money].freeze
ZAMBIAN_SHOPS = ['Shoprite Manda Hill', 'Pick n Pay Arcades', 'Melisa Supermarket', 'Spar Kabulonga',
                 'Game Stores', 'Hungry Lion', 'Debonairs Pizza', 'Zambeef Levy Junction',
                 'Pep Stores', 'Power Tools Zambia'].freeze

def create_realistic_transactions(user, categories, months_back: 4)
  transactions_config = {
    rent: { cat: :rent_mortgage, names: ['Monthly Rent'], range: 1200..2500, monthly: true, essential: true },
    electricity: { cat: :electricity, names: ['ZESCO Electricity'], range: 150..350, monthly: true, essential: true },
    water: { cat: :water, names: ['Lusaka Water'], range: 80..150, monthly: true, essential: true },
    groceries: { cat: :groceries, names: ['Weekly groceries', 'Market shopping', 'Shoprite groceries', 'Pick n Pay run'], range: 60..200, weekly: true, essential: true },
    transport: { cat: :transport, names: ['Fuel top-up', 'Minibus fare', 'Bolt ride', 'Vehicle service'], range: 25..180, freq: 8, essential: true },
    internet: { cat: :internet_phone, names: ['Zamtel Data Bundle', 'Airtel Monthly Plan'], range: 100..250, monthly: true, essential: false },
    dining: { cat: :dining_out, names: ['Lunch at Rhapsody', 'Coffee shop', 'Friday dinner out', 'Debonairs order'], range: 40..200, freq: 4, essential: false },
    entertainment: { cat: :entertainment, names: ['Movie night', 'DStv subscription', 'Bowling at Levy Park'], range: 50..300, freq: 2, essential: false },
    clothing: { cat: :clothing, names: ['Pep Stores clothes', 'Shoes from Game', 'Work outfit'], range: 80..400, freq: 1, essential: false },
    health: { cat: :healthcare, names: ['Pharmacy visit', 'Clinic checkup', 'Medical aid'], range: 50..500, freq: 1, essential: true },
    education: { cat: :education, names: ['Online course', 'Books', 'School supplies'], range: 50..300, freq: 1, essential: false },
  }

  months_back.downto(0) do |months_ago|
    month_date = months_ago.months.ago.to_date
    start_of_month = month_date.beginning_of_month
    end_of_month = month_date.end_of_month

    transactions_config.each do |_key, config|
      cat = categories[config[:cat]]
      next unless cat

      if config[:monthly]
        day = rand(1..5)
        date = [start_of_month + day.days, end_of_month].min
        create_payment(user, cat, config[:names].sample, rand(config[:range]), date, config[:essential])
      elsif config[:weekly]
        4.times do |week|
          day = start_of_month + (week * 7 + rand(0..2)).days
          next if day > end_of_month

          create_payment(user, cat, config[:names].sample, rand(config[:range]), day, config[:essential])
        end
      elsif config[:freq]
        config[:freq].times do
          day = start_of_month + rand(0..27).days
          next if day > end_of_month

          create_payment(user, cat, config[:names].sample, rand(config[:range]), day, config[:essential])
        end
      end
    end
  end
end

def create_payment(user, category, name, amount, date, essential)
  # Add natural variation: round to nearest 0.50 or whole number
  amount = (amount * 2).round / 2.0
  Payment.create!(
    user: user,
    category: category,
    name: name,
    amount: amount,
    payment_method: PAYMENT_METHODS.sample,
    is_essential: essential,
    created_at: date.to_datetime + rand(8..20).hours,
    updated_at: date.to_datetime + rand(8..20).hours
  )
end

# ─── Populate each user ─────────────────────────────────────────
puts ""
puts "Creating categories and transactions..."

all_users = [admin] + users.values
all_users.each do |user|
  cats = create_user_categories(user)
  months = user == admin ? 5 : 4
  create_realistic_transactions(user, cats, months_back: months)
  puts "  ✓ #{user.name}: #{user.categories.count} categories, #{user.payments.count} transactions"
end

# ─── Budgets ────────────────────────────────────────────────────
puts ""
puts "Creating budgets..."

all_users.each do |user|
  income = user.monthly_income || 5000
  budget_allocations = {
    rent_mortgage: 0.25, groceries: 0.15, transport: 0.10, electricity: 0.05,
    water: 0.03, internet_phone: 0.04, healthcare: 0.05, dining_out: 0.05,
    entertainment: 0.04, clothing: 0.03, education: 0.04, savings: 0.10
  }

  budget_allocations.each do |cat_key, pct|
    cat = user.categories.find_by(name: CategoryPreset.find_by(name: cat_key.to_s.titleize)&.name)
    next unless cat

    user.budgets.find_or_create_by!(category: cat) do |b|
      b.monthly_limit = (income * pct).round(2)
      b.start_date = Date.current.beginning_of_month
      b.end_date = Date.current.end_of_month
    end
  end
  puts "  ✓ #{user.name}: #{user.budgets.count} budgets"
end

# ─── Debts ──────────────────────────────────────────────────────
puts ""
puts "Creating debts..."

debt_scenarios = {
  professional: [
    { lender: 'Zanaco Personal Loan', principal: 25_000, rate: 28.5, payment: 1_200, term: 24, status: 'active' },
    { lender: 'Stanbic Car Loan', principal: 85_000, rate: 22.0, payment: 3_500, term: 48, status: 'active' },
  ],
  family: [
    { lender: 'FNB Home Loan', principal: 350_000, rate: 18.5, payment: 8_500, term: 240, status: 'active' },
    { lender: 'Bayport Financial', principal: 15_000, rate: 32.0, payment: 850, term: 24, status: 'active' },
    { lender: 'Atlas Mara Education Loan', principal: 12_000, rate: 25.0, payment: 600, term: 36, status: 'active' },
  ],
  student: [
    { lender: 'NATSAVE Student Loan', principal: 8_000, rate: 20.0, payment: 350, term: 36, status: 'active' },
  ],
}

users.each do |persona, user|
  debts = debt_scenarios[persona] || []
  debts.each do |d|
    user.debts.find_or_create_by!(lender_name: d[:lender]) do |debt|
      debt.principal_amount = d[:principal]
      debt.interest_rate = d[:rate]
      debt.monthly_payment = d[:payment]
      debt.term = d[:term]
      debt.status = d[:status]
      debt.start_date = rand(6..24).months.ago.to_date
    end
  end
  puts "  ✓ #{user.name}: #{user.debts.count} debts"
end

# ─── Financial Goals ────────────────────────────────────────────
puts ""
puts "Creating financial goals..."

goal_scenarios = {
  professional: [
    { name: 'Emergency Fund', type: 'saving', target: 25_000, current: 12_500, priority: 'high' },
    { name: 'Holiday to Cape Town', type: 'saving', target: 8_000, current: 3_200, priority: 'medium' },
    { name: 'Professional Certification', type: 'expense_reduction', target: 5_000, current: 2_000, priority: 'medium' },
  ],
  family: [
    { name: 'Emergency Fund (6 months)', type: 'saving', target: 72_000, current: 35_000, priority: 'high' },
    { name: 'Children School Fees', type: 'saving', target: 18_000, current: 8_000, priority: 'high' },
    { name: 'New Car Down Payment', type: 'saving', target: 50_000, current: 22_000, priority: 'medium' },
    { name: 'Family Vacation', type: 'saving', target: 12_000, current: 4_500, priority: 'low' },
  ],
  student: [
    { name: 'Laptop Fund', type: 'saving', target: 6_000, current: 3_800, priority: 'high' },
    { name: 'Graduation Savings', type: 'saving', target: 3_000, current: 1_200, priority: 'medium' },
  ],
}

users.each do |persona, user|
  goals = goal_scenarios[persona] || []
  goals.each do |g|
    user.financial_goals.find_or_create_by!(name: g[:name]) do |goal|
      goal.goal_type = g[:type]
      goal.target_amount = g[:target]
      goal.current_amount = g[:current]
      goal.start_date = rand(2..8).months.ago.to_date
      goal.target_date = rand(3..18).months.from_now.to_date
      goal.priority = g[:priority]
      goal.completed = false
    end
  end
  puts "  ✓ #{user.name}: #{user.financial_goals.count} goals"
end

# ─── Investments ────────────────────────────────────────────────
puts ""
puts "Creating investments..."

investment_scenarios = {
  professional: [
    { name: 'Lusaka Stock Exchange ETF', type: 'stocks', initial: 10_000, current: 11_500, institution: 'Stockbrokers Zambia' },
    { name: 'Fixed Deposit - Zanaco', type: 'fixed_deposit', initial: 15_000, current: 16_200, institution: 'Zanaco' },
  ],
  family: [
    { name: 'Government Treasury Bills', type: 'bonds', initial: 50_000, current: 55_000, institution: 'Bank of Zambia' },
    { name: 'Madison Asset Unit Trust', type: 'mutual_fund', initial: 25_000, current: 28_500, institution: 'Madison Financial' },
    { name: 'Airtel Money Fixed Savings', type: 'fixed_deposit', initial: 10_000, current: 10_800, institution: 'Airtel Money' },
  ],
  student: [
    { name: 'MTN MoMo Savings', type: 'savings_account', initial: 2_000, current: 2_150, institution: 'MTN Mobile Money' },
  ],
}

users.each do |persona, user|
  investments = investment_scenarios[persona] || []
  investments.each do |inv|
    user.investments.find_or_create_by!(name: inv[:name]) do |i|
      i.investment_type = inv[:type]
      i.initial_amount = inv[:initial]
      i.current_value = inv[:current]
      i.institution = inv[:institution]
      i.start_date = rand(3..12).months.ago.to_date
      i.active = true
      i.risk_level = rand(1..5)
    end
  end
  puts "  ✓ #{user.name}: #{user.investments.count} investments"
end

# ─── Recurring Transactions ─────────────────────────────────────
puts ""
puts "Creating recurring transactions..."

all_users.each do |user|
  rent_cat = user.categories.find_by(category_type: 'fixed')
  util_cat = user.categories.find_by(name: 'Electricity') || user.categories.find_by(category_type: 'fixed')
  internet_cat = user.categories.find_by(name: 'Internet & Phone') || user.categories.find_by(category_type: 'variable')
  groceries_cat = user.categories.find_by(category_type: 'groceries')

  income = user.monthly_income || 5000

  recurring = [
    { name: 'Monthly Rent', amount: (income * 0.25).round, freq: 'monthly', cat: rent_cat, essential: true },
    { name: 'ZESCO Bill', amount: rand(150..350), freq: 'monthly', cat: util_cat, essential: true },
    { name: 'Internet Bundle', amount: rand(100..250), freq: 'monthly', cat: internet_cat, essential: false },
    { name: 'Weekly Groceries', amount: rand(100..250), freq: 'weekly', cat: groceries_cat, essential: true },
  ]

  recurring.each do |r|
    next unless r[:cat]

    user.recurring_transactions.find_or_create_by!(name: r[:name]) do |rt|
      rt.category = r[:cat]
      rt.amount = r[:amount]
      rt.frequency = r[:freq]
      rt.start_date = 3.months.ago.to_date
      rt.next_occurrence = Date.current + rand(1..28).days
      rt.active = true
      rt.payment_method = PAYMENT_METHODS.sample
      rt.is_essential = r[:essential]
    end
  end
  puts "  ✓ #{user.name}: #{user.recurring_transactions.count} recurring"
end

# ─── Economic Indicators ────────────────────────────────────────
puts ""
puts "Creating economic indicators..."

6.downto(0) do |months_ago|
  date = months_ago.months.ago.to_date.end_of_month
  base_inflation = 10.5
  base_rate = 27.50

  EconomicIndicator.find_or_create_by!(date: date) do |ei|
    ei.inflation_rate = (base_inflation + rand(-1.5..1.5)).round(2)
    ei.usd_zmw_rate = (base_rate + rand(-2.0..3.0)).round(4)
    ei.source = 'Bank of Zambia'
  end
end
puts "  ✓ #{EconomicIndicator.count} economic indicator entries"

# ─── BNNB Data ──────────────────────────────────────────────────
puts ""
puts "Creating BNNB data..."

locations = ['Lusaka', 'Copperbelt', 'Southern', 'Eastern']
6.downto(0) do |months_ago|
  month = months_ago.months.ago.to_date.beginning_of_month
  locations.each do |location|
    base_food = location == 'Lusaka' ? 2800 : 2400
    base_non_food = location == 'Lusaka' ? 1600 : 1300
    food = (base_food + rand(-200..300)).round(2)
    non_food = (base_non_food + rand(-150..200)).round(2)

    BnnbData.find_or_create_by!(month: month, location: location) do |b|
      b.food_basket = food
      b.non_food_basket = non_food
      b.total_basket = food + non_food
    end
  end
end
puts "  ✓ #{BnnbData.count} BNNB data entries"

# ─── Summary ────────────────────────────────────────────────────
puts ""
puts "=" * 50
puts "  Seed data loaded successfully!"
puts "=" * 50
puts ""
puts "  Users:         #{User.count}"
puts "  Categories:    #{Category.count}"
puts "  Payments:      #{Payment.count}"
puts "  Budgets:       #{Budget.count}"
puts "  Debts:         #{Debt.count}"
puts "  Goals:         #{FinancialGoal.count}"
puts "  Investments:   #{Investment.count}"
puts "  Recurring:     #{RecurringTransaction.count}"
puts "  Economic Data: #{EconomicIndicator.count}"
puts "  BNNB Data:     #{BnnbData.count}"
puts ""
puts "  Login credentials (all use password: password123):"
puts "  Admin:        admin@keelfin.co.zm"
puts "  Professional: mwila@example.com"
puts "  Student:      bupe@example.com"
puts "  Family:       chileshe@example.com"
puts ""