class FetchBnnbDataJob < ApplicationJob
  queue_as :default
  
  def perform
    # Manual seeding for now - future: implement web scraping with Nokogiri
    Rails.logger.info "BNNB data fetch scheduled - seeding 2026 data"
    
    # Seed January 2026 data based on research
    BnnbData.find_or_create_by(month: Date.new(2026, 1, 1), location: 'Lusaka') do |bnnb|
      bnnb.total_basket = 11365.09
      bnnb.food_basket = 4900.00
      bnnb.non_food_basket = 6465.09
      bnnb.item_breakdown = {
        'charcoal' => 650.00,
        'kapenta' => 150.00,
        'vegetables' => 200.00,
        'mealie_meal' => 180.00,
        'rent' => 2500.00,
        'transport' => 800.00
      }
    end
    
    Rails.logger.info "BNNB data seeded successfully"
  rescue StandardError => e
    Rails.logger.error "Failed to fetch BNNB data: #{e.message}"
    raise e
  end
end
