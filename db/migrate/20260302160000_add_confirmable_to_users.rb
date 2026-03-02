class AddConfirmableToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string

    add_index :users, :confirmation_token, unique: true

    # Confirm all existing users so they aren't locked out
    User.update_all(confirmed_at: Time.current)
  end

  def down
    remove_index :users, :confirmation_token
    remove_column :users, :confirmation_token
    remove_column :users, :confirmed_at
    remove_column :users, :confirmation_sent_at
    remove_column :users, :unconfirmed_email
  end
end
