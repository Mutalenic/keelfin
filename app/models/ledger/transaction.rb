module Ledger
  # A complete financial event. A posted transaction must always have balanced
  # entries (total debits == total credits).
  class Transaction < ApplicationRecord
    STATUSES = %w[pending processing posted failed].freeze

    belongs_to :user
    has_many :entries, class_name: 'Ledger::Entry',
                       inverse_of: :ledger_transaction, dependent: :destroy
    has_many :accounts, through: :entries, source: :account
    has_many :audit_logs, class_name: 'Ledger::AuditLog',
                          inverse_of: :ledger_transaction, dependent: :nullify
    has_many :webhook_deliveries, class_name: 'Ledger::WebhookDelivery',
                                  inverse_of: :ledger_transaction, dependent: :destroy

    validates :description, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :idempotency_key, presence: true, uniqueness: true
    validates :transaction_type, presence: true

    validate :entries_must_balance, if: :posted?

    scope :recent, -> { order(created_at: :desc) }

    def posted?
      status == 'posted'
    end

    def failed?
      status == 'failed'
    end

    # Terminal states are never reprocessed by the idempotency guard.
    def terminal?
      posted? || failed?
    end

    # Parse the JSON metadata column into a hash.
    def metadata_hash
      return {} if metadata.blank?

      JSON.parse(metadata)
    rescue JSON::ParserError
      {}
    end

    private

    def entries_must_balance
      net = entries.to_a.sum do |entry|
        entry.direction == 'debit' ? entry.amount_cents : -entry.amount_cents
      end
      return if net.zero?

      errors.add(:entries, 'must balance — debits must equal credits')
    end
  end
end
