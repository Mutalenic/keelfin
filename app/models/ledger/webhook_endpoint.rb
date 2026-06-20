module Ledger
  # A user-registered URL that receives signed transaction event notifications.
  class WebhookEndpoint < ApplicationRecord
    belongs_to :user
    has_many :webhook_deliveries, class_name: 'Ledger::WebhookDelivery', dependent: :destroy

    validates :url, presence: true
    validate :url_must_be_valid

    before_validation :generate_secret, on: :create

    scope :active, -> { where(active: true) }

    private

    def url_must_be_valid
      return if url.blank?

      uri = URI.parse(url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(:url, 'must be a valid HTTP(S) URL')
      end
    rescue URI::InvalidURIError
      errors.add(:url, 'must be a valid HTTP(S) URL')
    end

    def generate_secret
      self.secret ||= SecureRandom.hex(32)
    end
  end
end
