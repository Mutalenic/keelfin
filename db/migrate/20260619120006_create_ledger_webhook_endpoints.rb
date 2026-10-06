class CreateLedgerWebhookEndpoints < ActiveRecord::Migration[7.2]
  def change
    create_table :ledger_webhook_endpoints do |t|
      t.references :user, null: false, foreign_key: true
      t.string :url, null: false
      t.string :secret, null: false # used for HMAC signing
      t.boolean :active, null: false, default: true
      t.string :event_types, array: true, null: false, default: []
      t.timestamps
    end

    add_index :ledger_webhook_endpoints, [:user_id, :active]
  end
end
