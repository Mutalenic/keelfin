class CategoryPreset < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :category_type, presence: true
  validates :category_type, inclusion: { in: %w[fixed variable discretionary groceries] }

  # Scopes
  scope :defaults, -> { where(is_default: true) }
  scope :by_type, ->(type) { where(category_type: type) }
  scope :ordered, -> { order(display_order: :asc, name: :asc) }
  scope :groceries, -> { where(category_type: 'groceries').ordered }
  scope :fixed, -> { where(category_type: 'fixed').ordered }
  scope :variable, -> { where(category_type: 'variable').ordered }
  scope :discretionary, -> { where(category_type: 'discretionary').ordered }

  # Class methods
  def self.seed_defaults
    return if CategoryPreset.any?

    # Grocery Categories
    grocery_categories = [
      { name: 'Fruits & Vegetables', icon: 'fa-apple-whole', icon_name: 'fa-solid fa-apple-whole', color: '#4CAF50',
        category_type: 'groceries', description: 'Fresh produce and vegetables', is_default: true, display_order: 1 },
      { name: 'Meat & Poultry', icon: 'fa-drumstick', icon_name: 'fa-solid fa-drumstick-bite', color: '#FF5722',
        category_type: 'groceries', description: 'Meat, poultry, and seafood products', is_default: true, display_order: 2 },
      { name: 'Dairy & Eggs', icon: 'fa-cheese', icon_name: 'fa-solid fa-cheese', color: '#FFEB3B',
        category_type: 'groceries', description: 'Milk, cheese, yogurt, and eggs', is_default: true, display_order: 3 },
      { name: 'Bakery', icon: 'fa-bread', icon_name: 'fa-solid fa-bread-slice', color: '#795548',
        category_type: 'groceries', description: 'Bread, pastries, and baked goods', is_default: true, display_order: 4 },
      { name: 'Canned Goods', icon: 'fa-can', icon_name: 'fa-solid fa-box', color: '#9E9E9E',
        category_type: 'groceries', description: 'Canned and preserved foods', is_default: true, display_order: 5 }
    ]

    # Essential Categories
    essential_categories = [
      { name: 'Housing', icon: 'fa-home', icon_name: 'fa-solid fa-home', color: '#2196F3', category_type: 'fixed',
        description: 'Rent, mortgage, and housing expenses', is_default: true, display_order: 1 },
      { name: 'Utilities', icon: 'fa-bolt', icon_name: 'fa-solid fa-bolt', color: '#FFC107', category_type: 'fixed',
        description: 'Electricity, water, and internet bills', is_default: true, display_order: 2 },
      { name: 'Transportation', icon: 'fa-car', icon_name: 'fa-solid fa-car', color: '#607D8B',
        category_type: 'variable', description: 'Fuel, public transport, and vehicle maintenance', is_default: true, display_order: 1 },
      { name: 'Healthcare', icon: 'fa-hospital', icon_name: 'fa-solid fa-hospital', color: '#F44336',
        category_type: 'variable', description: 'Medical expenses and health insurance', is_default: true, display_order: 2 }
    ]

    # Discretionary Categories
    discretionary_categories = [
      { name: 'Entertainment', icon: 'fa-film', icon_name: 'fa-solid fa-film', color: '#9C27B0',
        category_type: 'discretionary', description: 'Movies, events, and leisure activities', is_default: true, display_order: 1 },
      { name: 'Dining Out', icon: 'fa-utensils', icon_name: 'fa-solid fa-utensils', color: '#FF9800',
        category_type: 'discretionary', description: 'Restaurants, cafes, and takeout', is_default: true, display_order: 2 }
    ]

    # Create all presets
    (grocery_categories + essential_categories + discretionary_categories).each do |preset|
      CategoryPreset.create!(preset)
    end
  end

  # Instance methods
  def to_category_params
    {
      name: name,
      icon: icon,
      icon_name: icon_name,
      color: color,
      category_type: category_type,
      description: description
    }
  end
end
