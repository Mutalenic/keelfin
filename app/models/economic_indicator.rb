class EconomicIndicator < ApplicationRecord
  validates :date, presence: true, uniqueness: true
  validates :inflation_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :usd_zmw_rate, numericality: { greater_than: 0 }, allow_nil: true

  scope :recent, -> { order(date: :desc).limit(12) }

  def self.latest
    order(date: :desc).first
  end

  def self.latest_inflation
    latest&.inflation_rate
  end

  def self.latest_exchange_rate
    latest&.usd_zmw_rate
  end
end
