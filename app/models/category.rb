class Category < ApplicationRecord
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  has_many :payments, dependent: :destroy
  has_many :budgets, dependent: :destroy

  TYPES = %w[fixed variable discretionary groceries].freeze

  # Validations
  validates :name, presence: true, length: { maximum: 50 }
  validates :name, uniqueness: { scope: :user_id, message: "already exists for this user" }
  validates :icon, presence: true
  validates :category_type, inclusion: { in: %w[fixed variable discretionary groceries], allow_nil: true }
  
  # Scopes
  scope :groceries, -> { where(category_type: 'groceries') }
  scope :fixed, -> { where(category_type: 'fixed') }
  scope :variable, -> { where(category_type: 'variable') }
  scope :discretionary, -> { where(category_type: 'discretionary') }
  scope :by_type, ->(type) { where(category_type: type) }
  scope :ordered_by_name, -> { order(name: :asc) }

  # Methods
  def recent_transactions
    payments.order(created_at: :desc).limit(5)
  end

  def total_amount
    payments.sum(:amount)
  end
  
  def monthly_average
    payments.where('created_at >= ?', 3.months.ago).average(:amount) || 0
  end
  
  def percentage_of_total_spending
    user_total = user.total_spending
    return 0 if user_total.nil? || user_total.zero?
    
    ((total_amount / user_total) * 100).round(2)
  end
  
  def self.preset_categories
    [
      # Grocery Categories
      { name: 'Fruits & Vegetables', icon: 'fa-apple-whole', color: '#4CAF50', category_type: 'groceries', description: 'Fresh produce and vegetables' },
      { name: 'Meat & Poultry', icon: 'fa-drumstick-bite', color: '#FF5722', category_type: 'groceries', description: 'Meat, poultry, and seafood products' },
      { name: 'Dairy & Eggs', icon: 'fa-cheese', color: '#FFEB3B', category_type: 'groceries', description: 'Milk, cheese, yogurt, and eggs' },
      { name: 'Bakery', icon: 'fa-bread-slice', color: '#795548', category_type: 'groceries', description: 'Bread, pastries, and baked goods' },
      { name: 'Canned Goods', icon: 'fa-can-food', color: '#9E9E9E', category_type: 'groceries', description: 'Canned and preserved foods' },
      
      # Essential Categories
      { name: 'Housing', icon: 'fa-home', color: '#2196F3', category_type: 'fixed', description: 'Rent, mortgage, and housing expenses' },
      { name: 'Utilities', icon: 'fa-bolt', color: '#FFC107', category_type: 'fixed', description: 'Electricity, water, and internet bills' },
      { name: 'Transportation', icon: 'fa-car', color: '#607D8B', category_type: 'variable', description: 'Fuel, public transport, and vehicle maintenance' },
      { name: 'Healthcare', icon: 'fa-hospital', color: '#F44336', category_type: 'variable', description: 'Medical expenses and health insurance' },
      { name: 'Entertainment', icon: 'fa-film', color: '#9C27B0', category_type: 'discretionary', description: 'Movies, events, and leisure activities' }
    ]
  end
end
