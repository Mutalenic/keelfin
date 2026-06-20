module Ledger
  # Immutable record of every balance-affecting event. Audit logs may never be
  # updated or destroyed once written.
  class AuditLog < ApplicationRecord
    belongs_to :user
    belongs_to :ledger_transaction, class_name: 'Ledger::Transaction',
                                    foreign_key: :transaction_id, inverse_of: :audit_logs, optional: true
    belongs_to :account, class_name: 'Ledger::Account', optional: true

    validates :event_type, presence: true

    before_update { raise ActiveRecord::ReadOnlyRecord, 'Audit logs are immutable' }
    before_destroy { raise ActiveRecord::ReadOnlyRecord, 'Audit logs are immutable' }

    scope :recent, -> { order(created_at: :desc) }

    def balance_delta_ngwee
      return nil if balance_before_ngwee.nil? || balance_after_ngwee.nil?

      balance_after_ngwee - balance_before_ngwee
    end
  end
end
