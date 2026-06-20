module Ledger
  # A user-registered URL that receives signed transaction event notifications.
  class WebhookEndpoint < ApplicationRecord
    belongs_to :user
    has_many :webhook_deliveries, class_name: 'Ledger::WebhookDelivery', dependent: :destroy

    validates :url, presence: true,
                    format: { with: %r{\Ahttps?://}i, message: 'must be a valid HTTP(S) URL' }

    before_validation :generate_secret, on: :create

    scope :active, -> { where(active: true) }

    private

    def generate_secret
      self.secret ||= SecureRandom.hex(32)
    end
  end
end
