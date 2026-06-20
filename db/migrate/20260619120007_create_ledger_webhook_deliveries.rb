class CreateLedgerWebhookDeliveries < ActiveRecord::Migration[7.2]
  def change
    create_table :ledger_webhook_deliveries do |t|
      t.references :webhook_endpoint, null: false, foreign_key: { to_table: :ledger_webhook_endpoints }
      t.references :transaction, null: false, foreign_key: { to_table: :ledger_transactions }
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: 'pending' # pending, delivered, failed
      t.integer :http_status_code
      t.text :response_body
      t.integer :attempt_count, null: false, default: 0
      t.datetime :last_attempted_at
      t.timestamps
    end

    add_index :ledger_webhook_deliveries, [:webhook_endpoint_id, :status]
  end
end
