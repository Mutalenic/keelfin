# Seed file for preset categories
# This file contains all the preset categories for the DigiBudget application

# Only create preset categories if there are users in the system
if User.count > 0
  # Get the first user as a demo user
  demo_user = User.first
  
  # Grocery Categories
  grocery_categories = [
    { name: 'Fruits & Vegetables', icon: 'fa-apple-whole', icon_name: 'fa-solid fa-apple-whole', color: '#4CAF50', category_type: 'groceries', description: 'Fresh produce and vegetables' },
    { name: 'Meat & Poultry', icon: 'fa-drumstick', icon_name: 'fa-solid fa-drumstick-bite', color: '#FF5722', category_type: 'groceries', description: 'Meat, poultry, and seafood products' },
    { name: 'Dairy & Eggs', icon: 'fa-cheese', icon_name: 'fa-solid fa-cheese', color: '#FFEB3B', category_type: 'groceries', description: 'Milk, cheese, yogurt, and eggs' },
    { name: 'Bakery', icon: 'fa-bread', icon_name: 'fa-solid fa-bread-slice', color: '#795548', category_type: 'groceries', description: 'Bread, pastries, and baked goods' },
    { name: 'Canned Goods', icon: 'fa-can', icon_name: 'fa-solid fa-box', color: '#9E9E9E', category_type: 'groceries', description: 'Canned and preserved foods' },
    { name: 'Frozen Foods', icon: 'fa-snowflake', icon_name: 'fa-solid fa-snowflake', color: '#03A9F4', category_type: 'groceries', description: 'Frozen meals, vegetables, and desserts' },
    { name: 'Beverages', icon: 'fa-glass', icon_name: 'fa-solid fa-glass-water', color: '#2196F3', category_type: 'groceries', description: 'Drinks, water, and juices' },
    { name: 'Snacks', icon: 'fa-cookie', icon_name: 'fa-solid fa-cookie', color: '#FFC107', category_type: 'groceries', description: 'Chips, cookies, and other snack items' }
  ]
  
  # Essential Categories
  essential_categories = [
    { name: 'Housing', icon: 'fa-home', icon_name: 'fa-solid fa-home', color: '#2196F3', category_type: 'fixed', description: 'Rent, mortgage, and housing expenses' },
    { name: 'Utilities', icon: 'fa-bolt', icon_name: 'fa-solid fa-bolt', color: '#FFC107', category_type: 'fixed', description: 'Electricity, water, and internet bills' },
    { name: 'Transportation', icon: 'fa-car', icon_name: 'fa-solid fa-car', color: '#607D8B', category_type: 'variable', description: 'Fuel, public transport, and vehicle maintenance' },
    { name: 'Healthcare', icon: 'fa-hospital', icon_name: 'fa-solid fa-hospital', color: '#F44336', category_type: 'variable', description: 'Medical expenses and health insurance' },
    { name: 'Education', icon: 'fa-graduation-cap', icon_name: 'fa-solid fa-graduation-cap', color: '#9C27B0', category_type: 'variable', description: 'Tuition, books, and educational materials' }
  ]
  
  # Discretionary Categories
  discretionary_categories = [
    { name: 'Entertainment', icon: 'fa-film', icon_name: 'fa-solid fa-film', color: '#9C27B0', category_type: 'discretionary', description: 'Movies, events, and leisure activities' },
    { name: 'Dining Out', icon: 'fa-utensils', icon_name: 'fa-solid fa-utensils', color: '#FF9800', category_type: 'discretionary', description: 'Restaurants, cafes, and takeout' },
    { name: 'Shopping', icon: 'fa-shopping-bag', icon_name: 'fa-solid fa-shopping-bag', color: '#E91E63', category_type: 'discretionary', description: 'Clothing, electronics, and personal items' },
    { name: 'Gifts', icon: 'fa-gift', icon_name: 'fa-solid fa-gift', color: '#673AB7', category_type: 'discretionary', description: 'Presents and donations' },
    { name: 'Travel', icon: 'fa-plane', icon_name: 'fa-solid fa-plane', color: '#00BCD4', category_type: 'discretionary', description: 'Vacations, trips, and travel expenses' }
  ]
  
  # Financial Categories
  financial_categories = [
    { name: 'Savings', icon: 'fa-piggy-bank', icon_name: 'fa-solid fa-piggy-bank', color: '#4CAF50', category_type: 'fixed', description: 'Regular savings and emergency fund' },
    { name: 'Investments', icon: 'fa-chart-line', icon_name: 'fa-solid fa-chart-line', color: '#009688', category_type: 'fixed', description: 'Stocks, bonds, and other investments' },
    { name: 'Debt Payments', icon: 'fa-credit-card', icon_name: 'fa-solid fa-credit-card', color: '#F44336', category_type: 'fixed', description: 'Credit card, loan, and debt payments' },
    { name: 'Insurance', icon: 'fa-shield', icon_name: 'fa-solid fa-shield-alt', color: '#3F51B5', category_type: 'fixed', description: 'Life, auto, and home insurance' }
  ]
  
  # Combine all categories
  all_categories = grocery_categories + essential_categories + discretionary_categories + financial_categories
  
  # Create categories for the demo user if they don't exist
  all_categories.each do |category_data|
    # Skip if the category already exists for this user
    next if demo_user.categories.exists?(name: category_data[:name])
    
    # Create the category
    category = demo_user.categories.create!(category_data)
    puts "Created category: #{category.name}"
  end
  
  puts "Finished creating preset categories for #{demo_user.email}"
else
  puts "No users found. Skipping category creation."
end
