module Ledger
  # One side (debit or credit) of a double-entry transaction.
  class Entry < ApplicationRecord
    DIRECTIONS = %w[debit credit].freeze

    # `transaction` is reserved by ActiveRecord, so the association is named
    # `ledger_transaction` while the column remains `transaction_id`.
    belongs_to :ledger_transaction, class_name: 'Ledger::Transaction',
                                    foreign_key: :transaction_id, inverse_of: :entries
    belongs_to :account, class_name: 'Ledger::Account'

    validates :direction, inclusion: { in: DIRECTIONS }
    validates :amount_ngwee, numericality: { greater_than: 0, only_integer: true }
    validates :currency, presence: true

    def debit?
      direction == 'debit'
    end

    def credit?
      direction == 'credit'
    end
  end
end
