---
description: Development Playbook - Coding Standards and Best Practices
---

# Development Playbook for Digi Budget

This playbook defines the coding standards, best practices, and workflows to follow for all development tasks in the Digi Budget application.

## Table of Contents
1. [Code Review Checklist](#code-review-checklist)
2. [Ruby on Rails Standards](#ruby-on-rails-standards)
3. [Security Guidelines](#security-guidelines)
4. [Database & Performance](#database--performance)
5. [Error Handling](#error-handling)
6. [Testing Requirements](#testing-requirements)
7. [Git Workflow](#git-workflow)

---

## Code Review Checklist

Before committing any code, ensure you've checked ALL of the following:

### ✅ Critical Checks
- [ ] No nil reference errors (use safe navigation `&.` or explicit nil checks)
- [ ] All validations are in place for model fields
- [ ] No division by zero risks in calculations
- [ ] Authorization checks are not redundant
- [ ] No mass assignment vulnerabilities
- [ ] No hardcoded credentials or sensitive data

### ✅ Performance Checks
- [ ] No N+1 queries (use `includes`, `joins`, or `eager_load`)
- [ ] Database queries are optimized with proper indexes
- [ ] Expensive operations are cached where appropriate
- [ ] Background jobs are used for long-running tasks

### ✅ Code Quality Checks
- [ ] Methods are single-purpose and focused
- [ ] No code duplication (DRY principle)
- [ ] Proper error handling with specific exception classes
- [ ] Meaningful variable and method names
- [ ] Comments explain "why", not "what"

---

## Ruby on Rails Standards

### Controllers

**DO:**
```ruby
class BudgetsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource  # CanCan handles authorization
  
  def index
    @budgets = current_user.budgets.includes(:category).order(created_at: :desc)
  end
  
  def create
    @budget = current_user.budgets.new(budget_params)
    if @budget.save
      redirect_to budgets_path, notice: 'Budget created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  private
  
  def budget_params
    params.require(:budget).permit(:category_id, :monthly_limit)
  end
end
```

**DON'T:**
```ruby
# ❌ Redundant authorization checks
def update
  authorize! :update, @budget  # Already handled by load_and_authorize_resource
  @budget.update(budget_params)
end

# ❌ Missing error handling
def create
  @budget = Budget.create(budget_params)
  redirect_to budgets_path
end

# ❌ N+1 queries
def index
  @budgets = Budget.all  # Will cause N+1 when accessing budget.category
end
```

### Models

**DO:**
```ruby
class Debt < ApplicationRecord
  belongs_to :user
  
  # Validations - be specific and comprehensive
  validates :lender_name, presence: true
  validates :principal_amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[active paid_off] }, allow_nil: true
  
  # Scopes for common queries
  scope :active, -> { where(status: 'active') }
  
  # Safe calculations with nil checks
  def total_interest_cost
    return 0 unless monthly_payment && end_date && start_date
    return 0 if end_date < start_date
    
    months = ((end_date.year - start_date.year) * 12 + end_date.month - start_date.month)
    return 0 if months <= 0
    
    total_paid = monthly_payment * months
    interest = total_paid - principal_amount
    [interest, 0].max  # Ensure non-negative
  end
end
```

**DON'T:**
```ruby
# ❌ Missing validations
class Debt < ApplicationRecord
  belongs_to :user
end

# ❌ Unsafe calculations
def total_interest_cost
  (monthly_payment * months) - principal_amount  # Can be negative, no nil checks
end

# ❌ Mutating state without transaction safety
def adjust_for_inflation!(rate)
  self.monthly_limit *= (1 + rate / 100)
  save  # If save fails, object is in inconsistent state
end
```

### Views

**DO:**
```erb
<!-- Safe nil handling -->
<td><%= debt.interest_rate ? "#{number_with_precision(debt.interest_rate, precision: 1)}%" : 'N/A' %></td>

<!-- Proper Turbo method syntax -->
<%= button_to 'Delete', category, data: { turbo_method: :delete, turbo_confirm: 'Are you sure?' } %>

<!-- No user_id in forms (security) -->
<%= form_with(model: @category) do |form| %>
  <%= form.text_field :name %>
  <%= form.text_field :icon %>
<% end %>
```

**DON'T:**
```erb
<!-- ❌ No nil handling - will crash -->
<td><%= number_with_precision(debt.interest_rate, precision: 1) %>%</td>

<!-- ❌ Old method syntax -->
<%= button_to 'Delete', category, method: :delete %>

<!-- ❌ Security risk - user can manipulate user_id -->
<%= form.hidden_field :user_id, value: current_user.id %>
```

---

## Security Guidelines

### 1. Mass Assignment Protection
**Always use strong parameters:**
```ruby
def budget_params
  params.require(:budget).permit(:category_id, :monthly_limit, :start_date)
end
```

### 2. Authorization
**Use CanCanCan consistently:**
```ruby
# In Ability model
def initialize(user)
  return unless user.present?
  
  can :manage, Category, user_id: user.id
  can :manage, Payment, user_id: user.id
  can :manage, :all if user.admin?
end

# In controllers
load_and_authorize_resource  # Handles authorization automatically
```

### 3. SQL Injection Prevention
**Always use parameterized queries:**
```ruby
# ✅ GOOD
User.where('name = ?', params[:name])
User.where(name: params[:name])

# ❌ BAD
User.where("name = '#{params[:name]}'")
```

### 4. Sensitive Data
- Never commit API keys, passwords, or secrets
- Use Rails credentials or environment variables
- Add sensitive files to `.gitignore`

---

## Database & Performance

### 1. Avoid N+1 Queries
```ruby
# ✅ GOOD - Eager loading
@budgets = current_user.budgets.includes(:category)

# ❌ BAD - N+1 query
@budgets = current_user.budgets  # Will query for each budget.category
```

### 2. Optimize Service Objects
```ruby
# ✅ GOOD - Cache query results
def payoff_strategies
  active_debts = @user.debts.active
  
  {
    avalanche: active_debts.order(interest_rate: :desc).pluck(:lender_name, :interest_rate),
    snowball: active_debts.order(principal_amount: :asc).pluck(:lender_name, :principal_amount)
  }
end

# ❌ BAD - Duplicate queries
def payoff_strategies
  {
    avalanche: @user.debts.active.order(interest_rate: :desc).pluck(:lender_name, :interest_rate),
    snowball: @user.debts.active.order(principal_amount: :asc).pluck(:lender_name, :principal_amount)
  }
end
```

### 3. Use Database Indexes
Add indexes for frequently queried columns:
```ruby
add_index :payments, :user_id
add_index :payments, :category_id
add_index :payments, :created_at
add_index :budgets, [:user_id, :category_id]
```

---

## Error Handling

### 1. Specific Exception Handling
```ruby
# ✅ GOOD - Catch specific exceptions
def fetch_latest_usd_zmw
  # ... API call ...
rescue Net::OpenTimeout, Net::ReadTimeout => e
  Rails.logger.error "API timeout: #{e.message}"
  nil
rescue JSON::ParserError => e
  Rails.logger.error "JSON parse error: #{e.message}"
  nil
rescue SocketError, Errno::ECONNREFUSED => e
  Rails.logger.error "Network error: #{e.message}"
  nil
end

# ❌ BAD - Catch all exceptions
rescue StandardError => e
  Rails.logger.error "Error: #{e.message}"
  nil
end
```

### 2. Graceful Degradation
```ruby
# ✅ GOOD - Handle nil gracefully
def compare
  bnnb = BnnbData.where(month: @month).first
  return nil unless bnnb  # Return nil instead of crashing
  
  # ... rest of logic ...
end
```

### 3. User-Friendly Error Messages
```ruby
# ✅ GOOD
rescue_from CanCan::AccessDenied do |exception|
  redirect_to root_path, alert: 'You are not authorized to perform this action.'
end

# ❌ BAD
rescue_from CanCan::AccessDenied do |exception|
  raise exception  # Shows technical error to user
end
```

---

## Testing Requirements

### 1. Model Tests
Test validations, associations, and business logic:
```ruby
RSpec.describe Debt, type: :model do
  it { should validate_presence_of(:lender_name) }
  it { should validate_numericality_of(:principal_amount).is_greater_than(0) }
  it { should validate_inclusion_of(:status).in_array(%w[active paid_off]) }
  
  describe '#total_interest_cost' do
    it 'returns 0 when monthly_payment is nil' do
      debt = create(:debt, monthly_payment: nil)
      expect(debt.total_interest_cost).to eq(0)
    end
    
    it 'calculates interest correctly' do
      debt = create(:debt, principal_amount: 1000, monthly_payment: 100, 
                    start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 12, 31))
      expect(debt.total_interest_cost).to eq(200)
    end
  end
end
```

### 2. Controller Tests
Test authorization, happy paths, and error cases:
```ruby
RSpec.describe BudgetsController, type: :request do
  let(:user) { create(:user) }
  let(:budget) { create(:budget, user: user) }
  
  before { sign_in user }
  
  describe 'GET #index' do
    it 'returns success' do
      get budgets_path
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new budget' do
        expect {
          post budgets_path, params: { budget: attributes_for(:budget) }
        }.to change(Budget, :count).by(1)
      end
    end
    
    context 'with invalid params' do
      it 'does not create a budget' do
        expect {
          post budgets_path, params: { budget: { monthly_limit: -100 } }
        }.not_to change(Budget, :count)
      end
    end
  end
end
```

### 3. Feature Tests
Test user workflows end-to-end:
```ruby
RSpec.describe 'Budget management', type: :feature do
  it 'allows user to create a budget' do
    user = create(:user)
    category = create(:category, user: user)
    
    login_as(user)
    visit new_budget_path
    
    fill_in 'Monthly limit', with: 5000
    select category.name, from: 'Category'
    click_button 'Create Budget'
    
    expect(page).to have_content('Budget created successfully')
  end
end
```

---

## Git Workflow

### 1. Branch Naming
- Feature: `feature/budget-management`
- Bugfix: `bugfix/nil-reference-error`
- Hotfix: `hotfix/security-patch`

### 2. Commit Messages
Follow conventional commits:
```
feat: Add budget inflation adjustment feature
fix: Resolve nil reference error in debt view
refactor: Optimize N+1 queries in DebtAnalysisService
docs: Update development playbook with security guidelines
test: Add specs for Debt model validations
```

### 3. Pull Request Checklist
Before creating a PR:
- [ ] All tests pass (`bundle exec rspec`)
- [ ] Code follows style guide (`bundle exec rubocop`)
- [ ] No security vulnerabilities (`bundle exec brakeman`)
- [ ] Documentation is updated
- [ ] Self-review completed using this playbook

---

## Pre-Commit Checklist

Run this checklist before every commit:

```bash
# 1. Run tests
bundle exec rspec

# 2. Check code style
bundle exec rubocop

# 3. Check for security issues
bundle exec brakeman

# 4. Check for N+1 queries (in development)
# Visit pages and check logs for N+1 warnings

# 5. Manual code review
# Review your changes against this playbook
```

---

## Common Pitfalls to Avoid

### 1. Nil Reference Errors
Always check for nil before calling methods:
```ruby
# ✅ GOOD
debt.interest_rate ? "#{debt.interest_rate}%" : 'N/A'
@latest_data&.usd_zmw_rate

# ❌ BAD
debt.interest_rate.round(2)  # Crashes if nil
```

### 2. Division by Zero
Always validate denominators:
```ruby
# ✅ GOOD
return 0 if bnnb.food_basket.nil? || bnnb.food_basket.zero?
food_diff = (user_food_spending.to_f / bnnb.food_basket - 1) * 100

# ❌ BAD
food_diff = (user_food_spending / bnnb.food_basket - 1) * 100
```

### 3. Race Conditions
Use proper ActiveRecord methods:
```ruby
# ✅ GOOD
indicator = EconomicIndicator.find_or_initialize_by(date: Date.current)
indicator.usd_zmw_rate = rate
indicator.save

# ❌ BAD
indicator = EconomicIndicator.find_or_create_by(date: Date.current) do |ind|
  ind.usd_zmw_rate = rate
end
# Block not executed if record exists
```

### 4. State Mutation
Use update methods instead of manual assignment:
```ruby
# ✅ GOOD
new_limit = monthly_limit * (1 + inflation_rate / 100)
update(monthly_limit: new_limit)

# ❌ BAD
self.monthly_limit *= (1 + inflation_rate / 100)
save  # Object mutated even if save fails
```

---

## Version History

- **v1.0** (2026-02-24): Initial playbook created based on code review findings
  - Added security guidelines
  - Added performance optimization rules
  - Added error handling standards
  - Added testing requirements

---

## Maintenance

This playbook should be updated whenever:
- New patterns are established
- Security vulnerabilities are discovered
- Performance issues are identified
- Team agrees on new standards

**Last Updated:** 2026-02-24
**Maintained By:** Development Team
