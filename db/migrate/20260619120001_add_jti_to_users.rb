class AddJtiToUsers < ActiveRecord::Migration[7.2]
  # devise-jwt's JTIMatcher revocation strategy stores a per-user token id.
  # Existing users must be backfilled before the NOT NULL constraint is applied.
  def up
    add_column :users, :jti, :string
    execute "UPDATE users SET jti = gen_random_uuid()::text WHERE jti IS NULL"
    change_column_null :users, :jti, false
    add_index :users, :jti, unique: true
  end

  def down
    remove_index :users, :jti
    remove_column :users, :jti
  end
end
