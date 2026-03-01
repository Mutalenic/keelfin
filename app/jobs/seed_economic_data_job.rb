class SeedEconomicDataJob < ApplicationJob
  queue_as :default

  def perform
    # Seed 2026 economic indicators based on research
    seed_economic_indicators
    seed_bnnb_data

    Rails.logger.info 'Economic data seeded successfully'
  rescue StandardError => e
    Rails.logger.error "Failed to seed economic data: #{e.message}"
    raise e
  end

  private

  def seed_economic_indicators
    # January 2026 data
    EconomicIndicator.find_or_create_by(date: Date.new(2026, 1, 1)) do |indicator|
      indicator.inflation_rate = 9.4
      indicator.usd_zmw_rate = 19.0
      indicator.source = 'Manual seed - 2026 forecast'
    end

    # February 2026 data
    EconomicIndicator.find_or_create_by(date: Date.new(2026, 2, 1)) do |indicator|
      indicator.inflation_rate = 8.5
      indicator.usd_zmw_rate = 18.91
      indicator.source = 'Manual seed - 2026 forecast'
    end
  end

  def seed_bnnb_data
    # January 2026 JCTR BNNB data
    BnnbData.find_or_create_by(month: Date.new(2026, 1, 1).beginning_of_month, location: 'Lusaka') do |bnnb|
      bnnb.total_basket = 11_365.09
      bnnb.food_basket = 4900.00
      bnnb.non_food_basket = 6465.09
      bnnb.item_breakdown = {
        'charcoal' => 650.00,
        'kapenta' => 150.00,
        'vegetables' => 200.00,
        'mealie_meal' => 180.00,
        'beef' => 120.00,
        'beans' => 80.00,
        'rent' => 2500.00,
        'transport' => 800.00,
        'electricity' => 300.00
      }
    end

    # February 2026 JCTR BNNB data (slight increase due to inflation)
    BnnbData.find_or_create_by(month: Date.new(2026, 2, 1).beginning_of_month, location: 'Lusaka') do |bnnb|
      bnnb.total_basket = 11_500.00
      bnnb.food_basket = 4950.00
      bnnb.non_food_basket = 6550.00
      bnnb.item_breakdown = {
        'charcoal' => 680.00,
        'kapenta' => 160.00,
        'vegetables' => 210.00,
        'mealie_meal' => 185.00,
        'beef' => 125.00,
        'beans' => 85.00,
        'rent' => 2500.00,
        'transport' => 820.00,
        'electricity' => 310.00
      }
    end
  end
end
