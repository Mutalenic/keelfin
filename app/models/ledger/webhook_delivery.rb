module Ledger
  # Record of a single outbound webhook delivery attempt.
  class WebhookDelivery < ApplicationRecord
    STATUSES = %w[pending delivered failed].freeze

    belongs_to :webhook_endpoint, class_name: 'Ledger::WebhookEndpoint'
    belongs_to :ledger_transaction, class_name: 'Ledger::Transaction',
                                    foreign_key: :transaction_id, inverse_of: :webhook_deliveries

    validates :event_type, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :recent, -> { order(created_at: :desc) }

    def delivered?
      status == 'delivered'
    end
  end
end
