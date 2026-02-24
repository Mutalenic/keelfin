# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a demo user if none exists
unless User.exists?
  puts "Creating demo user..."
  User.create!(
    email: 'demo@example.com',
    password: 'password123',
    password_confirmation: 'password123',
    name: 'Demo User',
    monthly_income: 5000.00
  )
  puts "Demo user created successfully!"
end

# Seed category presets
puts "Seeding category presets..."
CategoryPreset.seed_defaults
puts "Category presets created successfully!"

# Create categories for users from presets
if User.exists? && CategoryPreset.exists?
  user = User.first
  
  # Only create categories if the user doesn't have many
  if user.categories.count < 5
    puts "Creating categories for #{user.email}..."
    
    # Create one category of each type from presets
    groceries_preset = CategoryPreset.groceries.first
    housing_preset = CategoryPreset.fixed.first
    transport_preset = CategoryPreset.variable.first
    entertainment_preset = CategoryPreset.discretionary.first
    
    # Create categories if presets exist and user doesn't have them already
    groceries = user.categories.find_by(name: groceries_preset&.name) || 
                (user.categories.create!(groceries_preset.to_category_params) if groceries_preset)
    
    housing = user.categories.find_by(name: housing_preset&.name) || 
              (user.categories.create!(housing_preset.to_category_params) if housing_preset)
    
    transport = user.categories.find_by(name: transport_preset&.name) || 
                (user.categories.create!(transport_preset.to_category_params) if transport_preset)
    
    entertainment = user.categories.find_by(name: entertainment_preset&.name) || 
                    (user.categories.create!(entertainment_preset.to_category_params) if entertainment_preset)
    
    puts "Categories created successfully!"
  end
  
  # Create some sample data if none exists
  if Payment.count == 0 && Category.exists?
    user = User.first
    
    # Get some categories - use what we have
    groceries ||= user.categories.find_by(category_type: 'groceries') || user.categories.first
    housing ||= user.categories.find_by(category_type: 'fixed') || user.categories.second
    transport ||= user.categories.find_by(category_type: 'variable') || user.categories.third
    
    if groceries && housing && transport
      # Create sample payments
      puts "Creating sample payments..."
      Payment.create!(
        user_id: user.id,
        category_id: groceries.id,
        name: 'Weekly grocery shopping',
        amount: 85.50,
        payment_method: 'cash',
        is_essential: true
      )
      
      Payment.create!(
        user_id: user.id,
        category_id: housing.id,
        name: 'Monthly rent',
        amount: 1200.00,
        payment_method: 'bank',
        is_essential: true
      )
      
      Payment.create!(
        user_id: user.id,
        category_id: transport.id,
        name: 'Fuel',
        amount: 65.75,
        payment_method: 'mtn_momo',
        is_essential: true
      )
      
      puts "Sample payments created successfully!"
    end
  end
end

puts "Seed data loaded successfully!"