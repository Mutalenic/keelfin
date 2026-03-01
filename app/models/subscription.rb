class Subscription < ApplicationRecord
  belongs_to :user

  # Constants for plan types
  PLANS = {
    free: {
      name: 'Free',
      price: 0.0,
      features: {
        max_categories: 10,
        max_budgets: 5,
        advanced_analytics: false,
        export_reports: false,
        shopping_lists: false,
        ai_insights: false,
        debt_strategies: false
      }
    },
    standard: {
      name: 'Standard',
      price: 135.0, # ~K135 (was $4.99)
      features: {
        max_categories: 50,
        max_budgets: 20,
        advanced_analytics: true,
        export_reports: true,
        shopping_lists: true,
        ai_insights: false,
        debt_strategies: false
      }
    },
    premium: {
      name: 'Premium',
      price: 270.0, # ~K270 (was $9.99)
      features: {
        max_categories: -1, # unlimited
        max_budgets: -1, # unlimited
        advanced_analytics: true,
        export_reports: true,
        shopping_lists: true,
        ai_insights: true,
        debt_strategies: true
      }
    }
  }.freeze

  # Validations
  validates :plan_name, presence: true, inclusion: { in: %w[free standard premium] }
  validates :status, presence: true, inclusion: { in: %w[active canceled expired pending] }
  validates :start_date, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :end_date_after_start_date, if: -> { end_date.present? }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :canceled, -> { where(status: 'canceled') }
  scope :expired, -> { where(status: 'expired') }
  scope :premium_plans, -> { where.not(plan_name: 'free') }

  # Callbacks
  before_create :set_default_features

  # Instance methods
  def active?
    status == 'active' && (end_date.nil? || end_date > Time.current)
  end

  def expired?
    end_date.present? && end_date < Time.current
  end

  def days_remaining
    return Float::INFINITY if end_date.nil?
    return 0 if expired?

    ((end_date - Time.current) / 1.day).ceil
  end

  def can_access_feature?(feature)
    return false unless active?

    features[feature.to_s] || false
  end

  def upgrade_to(new_plan)
    return false unless %w[free standard premium].include?(new_plan)

    # Don't downgrade from premium to standard
    return false if plan_name == 'premium' && new_plan == 'standard'

    # Don't process if same plan
    return true if plan_name == new_plan

    plan_data = PLANS[new_plan.to_sym]
    self.plan_name = new_plan
    self.amount = plan_data[:price]
    self.features = plan_data[:features]
    self.start_date = Time.current
    self.end_date = new_plan == 'free' ? nil : 1.month.from_now
    self.status = 'active'
    save
  end

  def cancel
    return false unless active?

    self.status = 'canceled'
    save
  end

  # Class methods
  def self.create_free_subscription(user)
    return false if user.subscription.present?

    plan_data = PLANS[:free]
    user.create_subscription(
      plan_name: 'free',
      status: 'active',
      start_date: Time.current,
      amount: 0.0,
      features: plan_data[:features]
    )
  end

  private

  def end_date_after_start_date
    return unless end_date <= start_date

    errors.add(:end_date, 'must be after start date')
  end

  def set_default_features
    return if features.present?

    self.features = PLANS[plan_name.to_sym][:features] if PLANS[plan_name.to_sym].present?
  end
end
