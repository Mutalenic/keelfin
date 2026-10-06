module Ledger
  # A financial account in the double-entry ledger. Balance is derived from its
  # entries; it is never stored directly so the ledger remains the source of truth.
  class Account < ApplicationRecord
    ACCOUNT_TYPES = %w[asset liability equity income expense].freeze
    # Normal balance side per account type (debit-normal vs credit-normal).
    DEBIT_NORMAL = %w[asset expense].freeze

    belongs_to :user
    has_many :entries, class_name: 'Ledger::Entry', dependent: :restrict_with_error
    has_many :ledger_transactions, through: :entries, source: :ledger_transaction

    validates :name, presence: true
    validates :account_type, inclusion: { in: ACCOUNT_TYPES }
    validates :currency, presence: true

    scope :active, -> { where(active: true) }

    def debit_normal?
      DEBIT_NORMAL.include?(account_type)
    end

    def balance_ngwee
      debits = entries.where(direction: 'debit').sum(:amount_ngwee)
      credits = entries.where(direction: 'credit').sum(:amount_ngwee)
      debit_normal? ? debits - credits : credits - debits
    end

    def balance
      Money.new(balance_ngwee, currency)
    end
  end
end
