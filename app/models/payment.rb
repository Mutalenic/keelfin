class Payment < ApplicationRecord
  belongs_to :user, class_name: 'User'
  belongs_to :category, class_name: 'Category'

  PAYMENT_METHODS = %w[cash mtn_momo airtel_money bank].freeze

  validates :name, presence: true, length: { maximum: 50 }
  validates :amount, presence: true, numericality: { greater_than: 0, less_than: 1_000_000 }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS, allow_nil: true }
  validate :category_belongs_to_user

  scope :recent, -> { order(created_at: :desc) }
  scope :this_month, -> { where(created_at: Date.current.beginning_of_month..) }
  scope :essential, -> { where(is_essential: true) }
  scope :discretionary, -> { where(is_essential: false) }
  scope :by_method, ->(method) { where(payment_method: method) }

  private

  def category_belongs_to_user
    return unless category && user

    errors.add(:category, 'must belong to you') if category.user_id != user_id
  end
end
