# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_02_24_093840) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bnnb_datas", force: :cascade do |t|
    t.date "month", null: false
    t.string "location", default: "Lusaka"
    t.decimal "total_basket", precision: 10, scale: 2, null: false
    t.decimal "food_basket", precision: 10, scale: 2, null: false
    t.decimal "non_food_basket", precision: 10, scale: 2, null: false
    t.jsonb "item_breakdown", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["month", "location"], name: "index_bnnb_datas_on_month_and_location", unique: true
  end

  create_table "budgets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.decimal "monthly_limit", precision: 10, scale: 2, null: false
    t.date "start_date"
    t.date "end_date"
    t.boolean "inflation_adjusted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_budgets_on_category_id"
    t.index ["user_id", "category_id", "start_date"], name: "index_budgets_on_user_id_and_category_id_and_start_date"
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "icon"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "debts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "lender_name", null: false
    t.decimal "principal_amount", precision: 12, scale: 2, null: false
    t.decimal "interest_rate", precision: 5, scale: 2
    t.decimal "monthly_payment", precision: 10, scale: 2
    t.integer "term"
    t.string "status", default: "active"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "status"], name: "index_debts_on_user_id_and_status"
    t.index ["user_id"], name: "index_debts_on_user_id"
  end

  create_table "economic_indicators", force: :cascade do |t|
    t.date "date", null: false
    t.decimal "inflation_rate", precision: 5, scale: 2
    t.decimal "usd_zmw_rate", precision: 8, scale: 4
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_economic_indicators_on_date", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.string "name"
    t.decimal "amount"
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_method"
    t.string "transaction_reference"
    t.boolean "is_essential", default: true
    t.text "notes"
    t.index ["amount"], name: "index_payments_on_amount"
    t.index ["category_id"], name: "index_payments_on_category_id"
    t.index ["created_at"], name: "index_payments_on_created_at"
    t.index ["user_id", "category_id"], name: "index_payments_on_user_id_and_category_id"
    t.index ["user_id", "created_at"], name: "index_payments_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "role", default: "default", null: false
    t.decimal "monthly_income", precision: 10, scale: 2
    t.string "currency", default: "ZMW"
    t.string "phone_number"
    t.string "mtn_momo_number"
    t.string "airtel_money_number"
    t.boolean "two_factor_enabled", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "budgets", "categories"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "debts", "users"
  add_foreign_key "payments", "categories"
  add_foreign_key "payments", "users"
end
